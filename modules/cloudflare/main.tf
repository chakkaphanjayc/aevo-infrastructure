terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

variable "zone_id" {
  type = string
}

variable "records" {
  type = map(object({
    name    = string
    content = string
    type    = string
    proxied = optional(bool, true)
    ttl     = optional(number, 1)
  }))
  default = {}
}

resource "cloudflare_dns_record" "app" {
  for_each = var.records
  zone_id  = var.zone_id
  name     = each.value.name
  content  = each.value.content
  type     = each.value.type
  proxied  = each.value.proxied
  ttl      = each.value.ttl
}
