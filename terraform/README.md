# Data Engineering AWS API Gateway to S3
Overall, this project offers a serverless solution for securely uploading files to an S3 bucket and enables the integration of event-driven notifications using AWS services.

## Description
This project aims to create a serverless infrastructure using Terraform. The infrastructure includes an API Gateway, a Lambda function, an SNS topic, and CloudWatch Logs.

The main purpose of the project is to provide a presigned URL retrieval mechanism for uploading files to a private S3 bucket through HTTP requests. The API Gateway acts as the entry point for these requests, while the Lambda function generates the presigned URL and handles the file upload process. The S3 bucket serves as the storage location for the uploaded files.

Additionally, the project utilizes an SNS topic to send notifications related to the file uploads. Subscribers can receive email notifications by subscribing their email addresses to the SNS topic.

This project aims to provision and manage infrastructure resources using Terraform. It provides a convenient way to automate the creation and management of infrastructure components.

## Prerequisites

Before you begin, ensure that you have the following prerequisites installed:

- [Docker](https://www.docker.com/): Latest version if possible
- [Docker-Compose](https://docs.docker.com/compose/): Latest version if possible

## Getting Started

Follow these instructions to get the project up and running:

1. Clone the repository: `git clone https://github.com/your-username/your-repo.git`
2. Change into the project directory: `cd your-repo`
3. Change into the project's Terraform subfolder: `cd terraform`
# TODO

add the connection to AWS
use the Makefile to run your target recepies


3. Run `terraform init` to initialize the project and download the necessary provider plugins.
4. Customize the configuration files to match your desired infrastructure setup.
5. Run `terraform plan` to review the planned changes and verify the configuration.
6. Run `terraform apply` to create or modify the infrastructure based on your configuration.
7. Access and test your infrastructure resources.

## Configuration

The project configuration is managed through Terraform. You can find the main configuration files in the following locations:

- `main.tf`: Contains the main infrastructure resources and their configurations.
- `variables.tf`: Defines input variables that can be customized to adjust the infrastructure setup.
- `outputs.tf`: Specifies the output values exposed by the infrastructure resources.

Feel free to modify these files according to your requirements. Additionally, you can create additional files and modules as needed.

## Additional Resources

Here are some additional resources that can help you learn more about Terraform:

- [Terraform Documentation](https://www.terraform.io/docs/index.html): Official documentation for Terraform.
- [Terraform Registry](https://registry.terraform.io/): Browse and search for community-contributed Terraform modules and providers.
- [Terraform GitHub Repository](https://github.com/hashicorp/terraform): Official GitHub repository for Terraform.

## Contributing

If you would like to contribute to this project, please follow the guidelines outlined in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Mention any individuals, organizations, or resources that you found helpful during your work on this project.

Feel free to customize this template according to your project's specific details and requirements.