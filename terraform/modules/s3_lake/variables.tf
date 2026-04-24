variable "project" {}
variable "env" {}
variable "bucket_name" {}
variable "tags" {
  type = map(string)
}
variable "account_id" {
  type = string
}