# A dictionary containing tags that will be applied to all resources from this module
variable "tags" {

}

# A list of subnet ids that the compute environment for this module can use
# They must be subnets with access to internet
variable "subnets" {

}
variable "region" {
  default = "eu-central-1"
}

# Path to a folder containing all of the repo files to be uploaded to /etc/yum.repos.d
variable "repos_path" {

}
# A VPC to deploy the repository in.
variable "vpc" {

}