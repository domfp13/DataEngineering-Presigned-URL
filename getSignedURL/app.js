// Created by: Luis Enrique Fuentes Plata

'use strict'

const AWS = require('aws-sdk')
AWS.config.update({region: process.env.AWS_REGION})
const s3 = new AWS.S3()

// Change this value to adjust the signed URL's expiration
const URL_EXPIRATION_SECONDS = 900

// This object is used to validate if file should be process or not
const filePath = {
    'Tester.xlsx': '/',
    'Tester2.xlsx': '/'
}

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Context doc: https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html
 * @param {Object} context
 *
 * Callback doc: https://docs.aws.amazon.com/lambda/latest/dg/nodejs-handler.html
 * @param {Object} callback
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */
exports.lambdaHandler = async (event, context, callback) => {

    let fileName = getFileName(event);

    if (filePath[fileName] && filePath[fileName] !== "") {
        // HTTP 200 OK, send URL
        return await getUploadURL(fileName);
    } else {

        let params = {
            Message: 'The following file: ' + fileName + ' is not accepted!',
            TopicArn: process.env.SNS_TOPIC_ARN
        };

        // Send Email
        let publishTextPromise = new AWS.SNS({apiVersion: '2010-03-31'}).publish(params).promise();

        // Handle promise's fulfilled/rejected states
        publishTextPromise.then(
            function (data) {
                console.log(`Message ${params.Message} sent to the topic ${params.TopicArn}`);
                console.log("MessageID is " + data.MessageId);
            }).catch(
            function (err) {
                console.error(err, err.stack);
            });

        callback("[BadRequest] Validation error: File is not accepted!");
    }

}

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns string fileName - File's name to be inserted into S3 bucket
 *
 */
const getFileName = function (event) {

    if (event.headers && event.headers !== "") {
        return event.headers['file-name'];
    }

};

/**
 *
 * fileName str:
 * @param fileName string - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} - HTTP response
 *
 */
const getUploadURL = async function (fileName) {

    const Key = `${fileName}`;

    // Get signed URL from S3
    const s3Params = {
        Bucket: process.env.UploadBucket,
        Key,
        Expires: URL_EXPIRATION_SECONDS,
        ContentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    // This will keep the longs in CloudWatch
    console.log('Params: ', s3Params);

    const uploadURL = await s3.getSignedUrlPromise('putObject', s3Params);

    return JSON.stringify({
        uploadURL: uploadURL,
        Key
    });
}
