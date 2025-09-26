
module "eventbridge_s3_object_create" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.1.0"

  create_bus  = false
  create_role = true
  role_name   = "eventbridge_s3_object_create_role"

  attach_policy_json = true

  policy_json = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ActionsForResource",
            "Effect": "Allow",
            "Action": [
                "glue:NotifyEvent"
            ],
            "Resource": [
                "${aws_glue_workflow.zeek_workflow.arn}"
            ]
        }
    ]
}
EOF


  rules = {
    s3_object_create = {
      event_pattern = jsonencode({
        source      = ["aws.s3"],
        detail-type = ["Object Created"],
        detail = {
          bucket = {
            name = [module.s3_bucket.s3_bucket_id]
          }
        }
      })
      enabled = true
    }
  }

  targets = {
    s3_object_create = [
      {
        name            = "trigger_glue_workflow"
        arn             = aws_glue_workflow.zeek_workflow.arn
        attach_role_arn = true
      }
    ]
  }

}

module "eventbridge_glue_crawler_succeeded" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.1.0"

  create_bus         = false
  create_role        = true
  role_name          = "eventbridge_glue_crawler_succeeded_role"
  lambda_target_arns = [module.lambda_function.lambda_function_arn]

  attach_lambda_policy = true

  rules = {
    glue_crawler_succeeded = {
      event_pattern = jsonencode({
        source      = ["aws.glue"],
        detail-type = ["Glue Crawler State Change"],
        detail = {
          state       = ["Succeeded"],
          crawlerName = [aws_glue_crawler.zeek_crawler.id]
        }
      })
      enabled = true
    }
  }

  targets = {
    glue_crawler_succeeded = [
      {
        name            = "trigger_lambda"
        arn             = module.lambda_function.lambda_function_arn
        attach_role_arn = true
      }
    ]
  }

}
