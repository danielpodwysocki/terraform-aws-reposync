# Runs the sync on a schedule using EventBridge

resource "aws_cloudwatch_event_rule" "cron_aws-reposync" {
  name                = "cron_aws-repsoync"
  description         = "An event on a cron schedule, triggering a reposync task in ECS"
  schedule_expression = "cron(${var.cron})"

  tags = var.tags
}

resource "aws_iam_role" "ecs_events" {
  name = "ecs_events"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name = "ecs_events_run_task_with_any_role"
  role = aws_iam_role.ecs_events.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(aws_ecs_task_definition.aws-reposync.arn, "/:\\d+$/", ":*")}"
        }
    ]
}
DOC
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  arn      = aws_ecs_cluster.aws-reposync.arn
  rule     = aws_cloudwatch_event_rule.cron_aws-reposync.name
  role_arn = aws_iam_role.ecs_events.arn

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.aws-reposync.arn
    network_configuration {
      subnets          = var.subnets
      assign_public_ip = true
    }
    tags = var.tags

  }

}
