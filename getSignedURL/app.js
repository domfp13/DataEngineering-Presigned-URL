// Created by: Enrique Plata

// strict is a directive that enables strict mode in JavaScript. When strict mode is enabled, it enforces stricter rules and provides better error handling, leading to more robust and predictable code.
'use strict'

const AWS = require('aws-sdk');
AWS.config.update({region: process.env.AWS_REGION});
const csv = require('csv-parser');

// URL expiration time in seconds, this time is for how long the presigned URL will be valid. 
const URL_EXPIRATION_SECONDS = 300;

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns string fileName - File's name to be inserted into S3 bucket
 *
 */
const getEventFileName = function (event) {
    if (event.headers && event.headers !== "") {
        console.log('headers: ', event.headers);
        return event.headers['file-name'];
    }
};

// get the getApiGateWayPath "path" from the event
const getApiGateWayPath = function (event) {
    if (event.headers && event.headers !== "") {
        console.log('headers: ', event.headers);
        return event.path;
    }
}

// Function to download the CSV file from S3
async function downloadFileFromS3(bucketName, key) {
    const s3 = new AWS.S3();
    const s3Params = { Bucket: bucketName, Key: key };
    const s3Stream = s3.getObject(s3Params).createReadStream();
    return s3Stream;
}

// Function to parse the CSV file and return the list of records
async function parseCSV(s3Stream) {
    return new Promise((resolve, reject) => {
        const results = [];
        s3Stream
            .pipe(csv({ skipLines: 1 })) // Skip the first row (header)
            .on('data', (data) => {
                const values = Object.values(data);
                results.push(...values);
            })
            .on('end', () => {
                resolve(results); // Return the list of values from the CSV file
            })
            .on('error', (error) => {
                reject(error);
            });
    });
}

/**
 *
 * fileName str:
 * @param fileName string - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} - HTTP response
 *
 */
const getUploadURL = async function (fileName, path, bucketName) {
    // instanciate S3 client
    const s3 = new AWS.S3()

    const Key = path + `${fileName}`;

    // Determine content type based on file extension
    let ContentType;
    if (fileName.endsWith('.xlsx')) {
        ContentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (fileName.endsWith('.csv')) {
        ContentType = 'text/csv';
    }

    // Get signed URL from S3
    const s3Params = {
        Bucket: bucketName,
        Key,
        Expires: URL_EXPIRATION_SECONDS,
        ContentType,
    };

    const uploadURL = await s3.getSignedUrlPromise('putObject', s3Params);

    console.log('INFO:', uploadURL);

    return {
        statusCode: 200,
        body: JSON.stringify({
          uploadURL: uploadURL,
          Key: Key
        })
    };    
    
    // return JSON.stringify({
    //     uploadURL: uploadURL,
    //     Key
    // });
}

exports.lambdaHandler = async (event, context, callback) => {
    try {

        // Check if "file-name" header is present in the event
        if (!event.headers || !event.headers['file-name']) {
            const errorMessage = 'Missing "file-name" header';
            console.error('Error:', errorMessage);

            // Return an HTTP error response
            return {
                statusCode: 400,
                body: JSON.stringify({ error: errorMessage }),
            };
        }

        // Get the file name from the event
        const { BUCKET_NAME } = process.env;
        const bucketName = BUCKET_NAME;
        
        // Inside of the S3 bucket should be a file called mapping.csv which is used for validation of the files that are allowed to be uploaded
        const key = 'mapping.csv';

        // Download the CSV file from S3
        const s3Stream = await downloadFileFromS3(bucketName, key);

        // Parse the CSV file and get the list of records
        const records = await parseCSV(s3Stream);

        // Getting the file name from API Gateway event
        let fileName = getEventFileName(event);

        // Check if the file name provided in the json body is valid in the mapping.csv file
        if (records.includes(fileName)) {
            console.log('INFO:', "File name is valid: ", fileName);
            
            // Getitng the AWS API Gateway stage (prod or qc)
            if(getApiGateWayPath(event).includes('prod')){
                console.log('INFO:', "PROD prefix");
                return await getUploadURL(fileName, 'prod/', bucketName);
            }else{
                console.log('INFO:', "QC prefix");
                return await getUploadURL(fileName, 'qc/', bucketName);
            }

        } else {
            console.log("File name is invalid");

            const errorMessage = 'Unsupported file, is not part of the mapping.csv list';
            console.error('Error:', errorMessage);

            // Return an HTTP error response
            return {
                statusCode: 415,
                body: JSON.stringify({ error: errorMessage }),
            };
        }
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error }),
        };
    }
}
