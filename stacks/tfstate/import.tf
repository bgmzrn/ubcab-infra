# Existing nonprod state bucket from bootstrap-bucket.sh (create only).
# Companion resources (versioning, encryption, …) are created by this stack.
import {
  to = aws_s3_bucket.state
  id = "tfstates-606284766767-ap-southeast-1"
}
