locals {
  tags = {
    "managed_by" = "terraform"
  }
  identifier = "hn-${var.environment}-${var.region_short}"
  ip_ranges  = ["81.132.129.133"] 
}
