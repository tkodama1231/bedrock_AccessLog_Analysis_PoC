### bucket for zeek logs

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "${var.s3_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  versioning = {
    enabled = true
  }
}

module "s3_notifications" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "5.1.0"

  bucket = module.s3_bucket.s3_bucket_id

  eventbridge = true

}

### bucket for athena query results

module "s3_bucket_athena_results" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "${var.s3_bucket_athena_results_prefix}-${data.aws_caller_identity.current.account_id}"

  versioning = {
    enabled = true
  }
}
