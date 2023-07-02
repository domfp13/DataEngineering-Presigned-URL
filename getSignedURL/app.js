const AWS = require('aws-sdk');
const csv = require('csv-parser');

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
        const { BUCKET_NAME, SNS_TOPIC_ARN } = process.env;
        const bucketName = BUCKET_NAME;
        const key = 'mapping.csv';
        //const results = [];

        // Download the CSV file from S3
        const s3Stream = await downloadFileFromS3(bucketName, key);

        // Parse the CSV file and get the list of records
        const records = await parseCSV(s3Stream);
        //const records = await parseCSV(s3Stream, results);

        // Getting the file name from API Gateway event
        let fileName = getEventFileName(event);

        if (records.includes(fileName)) {
            console.log("File name is valid");
        } else {
            console.log("File name is invalid");
        }

    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
}
