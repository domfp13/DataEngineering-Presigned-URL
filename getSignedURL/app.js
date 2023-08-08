'use strict';

const AWS = require('aws-sdk');
const csv = require('csv-parser');
const stream = require('stream');

AWS.config.update({ region: process.env.AWS_REGION });

// URL expiration time in seconds, this time is for how long the presigned URL will be valid.
const URL_EXPIRATION_SECONDS = 300;

// Create a single S3 client object and reuse it throughout the Lambda function
const s3 = new AWS.S3();

/**
 * Downloads a file from an S3 bucket and returns a readable stream.
 * @param {string} bucketName - The name of the S3 bucket.
 * @param {string} key - The key of the file in the S3 bucket.
 * @returns {ReadableStream} - A readable stream of the file contents.
 */
const downloadFileFromS3 = async (bucketName, key) => {
    const s3Params = { Bucket: bucketName, Key: key };
    try {
        const s3Object = await s3.getObject(s3Params).promise();
        // Create a readable stream from the S3 object buffer using the stream.Readable.from() method
        const s3Stream = stream.Readable.from(s3Object.Body);
        return s3Stream;
    } catch (error) {
        console.error(`Failed to download S3 object: ${error}`);
        throw new Error('Failed to download S3 object');
    }
};

/**
 * Parses a CSV file from a readable stream and returns the list of records.
 * @param {ReadableStream} s3Stream - A readable stream of the CSV file contents.
 * @returns {Promise<Array>} - A promise that resolves to an array of records from the CSV file.
 */
const parseCSV = async (s3Stream) => {
    const results = [];
    return new Promise((resolve, reject) => {
        s3Stream
            .pipe(csv({
                skipLines: (line) => line.trim() === ''
            }))
            .on('data', (data) => {
                const values = Object.values(data);
                results.push(...values);
            })
            .on('end', () => {
                resolve(results);
            })
            .on('error', (error) => {
                console.error(`Failed to parse CSV file: ${error}`);
                reject(new Error('Failed to parse CSV file'));
            });
    });
};

/**
 * Generates a presigned URL for uploading a file to an S3 bucket.
 * @param {string} fileName - The name of the file to be uploaded.
 * @param {string} path - The path prefix to be used in the S3 key.
 * @param {string} bucketName - The name of the S3 bucket.
 * @returns {Promise<Object>} - A promise that resolves to an HTTP response object containing the presigned URL and S3 key.
 */
const getUploadURL = async (fileName, path, bucketName) => {
    const Key = `${path}${fileName}`;
    const ContentType = fileName.endsWith('.xlsx')
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'text/csv';
    const s3Params = {
        Bucket: bucketName,
        Key,
        Expires: URL_EXPIRATION_SECONDS,
        ContentType,
    };
    try {
        const uploadURL = await s3.getSignedUrlPromise('putObject', s3Params);
        return {
            statusCode: 200,
            body: JSON.stringify({
                uploadURL,
                Key,
            }),
        };
    } catch (error) {
        console.error(`Failed to generate presigned URL: ${error}`);
        throw new Error('Failed to generate presigned URL');
    }
};

/**
 * Get's the path from the API Gateway event and returns astring with the path prefix.
 * @param {string} event - JSON object containing the API Gateway event.
 * @returns {string} - A string with the path prefix.
 */
const getApiGateWayPath = function (event) {
    if (event.headers && event.headers !== "") {
        console.log('headers: ', event.headers);
        return event.path;
    }
}

/**
 * Lambda function handler that generates a presigned URL for uploading a file to an S3 bucket.
 * @param {Object} event - The API Gateway Lambda Proxy Input Format event.
 * @returns {Promise<Object>} - A promise that resolves to an HTTP response object containing the presigned URL and S3 key.
 */
exports.lambdaHandler = async (event) => {
    try {
        // Get the name of the s3 api-bucket from the environment variables
        const apiBucketName = process.env.BUCKET_NAME_API;

        // Print out the eventJSON object to the log
        console.log('eventJSON: ', event);

        // Convert the JSON object to a string
        const fileContent = JSON.stringify(event);

        // Create an S3 client
        const s3 = new AWS.S3();

        // upload the file to the api-bucket s3 bucket
        const s3Params = {
            Bucket: apiBucketName,
            Key: 'Testing.json',
            Body: fileContent,
            ContentType: "application/json"
        };

        // Upload the file to the s3 bucket
        s3.upload(s3Params, function (err, data) {
            if (err) {
                console.log("Error", err);
            }
        });
        
        // Get the name of the S3 bucket from the environment variables
        const bucketName = process.env.BUCKET_NAME;
        const key = 'mapping.csv';
        // Download the CSV file from S3
        const s3Stream = await downloadFileFromS3(bucketName, key);
        // Parse the CSV file and get the list of records
        const records = await parseCSV(s3Stream);
        // Get the file name from the "file-name" header of the API Gateway event
        const fileName = event.headers?.['file-name'];
        if (!fileName) {
            const errorMessage = 'Missing "file-name" header';
            console.error(`Error: ${errorMessage}`);
            // Return an HTTP error response
            return {
                statusCode: 400,
                body: JSON.stringify({ error: errorMessage }),
            };
        }
        // Check if the file name provided in the json body is valid in the mapping.csv file
        if (await records.includes(fileName)) {
            // Determine the path prefix based on the API Gateway stage (prod or qc)
            const path = getApiGateWayPath(event).includes('prod') ? 'prod/' : 'qc/';
            // Generate a presigned URL for uploading the file to S3
            return await getUploadURL(fileName, path, bucketName);
        } else {
            const errorMessage = 'Unsupported file, is not part of the mapping.csv list';
            console.error(`Error: ${errorMessage}`);
            // Return an HTTP error response
            return {
                statusCode: 415,
                body: JSON.stringify({ error: errorMessage }),
            };
        }
    } catch (error) {
        console.error(`Error: ${error}`);
        // Return an HTTP error response
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message }),
        };
    }
};