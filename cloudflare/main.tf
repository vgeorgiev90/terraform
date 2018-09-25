provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}
/*
resource "cloudflare_record" "domain-A" {
  count  = "${var.A_record_count}"
  domain = "${var.domain}"
  name   = "${var.A_record_name[count.index]}"
  value  = "${var.A_record_value[count.index]}"
  type   = "A"
  ttl    = 3600
}

resource "cloudflare_record" "domain-TXT" {
  count  = "${var.TXT_record_count}"
  domain = "${var.domain}"
  name   = "${var.TXT_record_name[count.index]}"
  value  = "${var.TXT_record_value[count.index]}"
  type   = "A"
  ttl    = 3600
}

resource "cloudflare_record" "domain-MX" {
  count  = "${var.MX_record_count}"
  domain = "${var.domain}"
  name   = "${var.MX_record_name[count.index]}"
  value  = "${var.MX_record_value[count.index]}"
  type   = "A"
  ttl    = 3600
}

resource "cloudflare_record" "domain-CNAME" {
  count  = "${var.CNAME_record_count}"
  domain = "${var.domain}"
  name   = "${var.CNAME_record_name[count.index]}"
  value  = "${var.CNAME_record_value[count.index]}"
  type   = "A"
  ttl    = 3600
}
*/

########## Domain specific page rules ################ 

resource "cloudflare_page_rule" "domain-page-rule" {
  zone = "${var.domain}"
  target = "${var.domain}/"
  priority = 1

  actions = {
    browser_cache_ttl = "30",
    cache_level = "cache_everything",
    edge_cache_ttl = "240"
  }
}

resource "cloudflare_page_rule" "domain-page-rule2" {
  zone = "${var.domain}"
  target = "${var.domain}/*"
  priority = 2

  actions = {
    browser_cache_ttl = "240",
    browser_check = "off",
    cache_level = "bypass",
    disable_performance = false,
    always_online = "off",
    security_level = "low",
    ssl = "full",
    mirage = "off"
  }
}

resource "cloudflare_page_rule" "domain-page-rule3" {
  zone = "${var.domain}"
  target = "${var.domain}"
  priority = 3

  actions = {
    browser_check = "off",
    always_online = "off",
    security_level = "low",
    waf = "off"
  }
}

resource "cloudflare_page_rule" "domain-page-rule4" {
  zone = "${var.domain}"
  target = "${var.domain}"
  priority = 4

  actions = {
    disable_security = "true",
    security_level = "essentially_off",
    disable_performance = false,
    mirage = "off",
    browser_cache_ttl = "240",
  }
}

resource "cloudflare_page_rule" "domain-page-rule5" {
  zone = "${var.domain}"
  target = "${var.domain}/Widgets/v6/*"
  priority = 5

  actions = {
    browser_cache_ttl = "30",
    cache_level = "cache_everything",
    edge_cache_ttl = "240"
  }
}

resource "cloudflare_page_rule" "domain-page-rule6" {
  zone = "${var.domain}"
  target = "${var.domain}/AffiliateAdmin/Preferences.aspx"
  priority = 6

  actions = {
    waf = "off"
  }
}

resource "cloudflare_page_rule" "domain-page-rule7" {
  zone = "${var.domain}"
  target = "${var.domain}/release_notes/*"
  priority = 7

  actions = {
    cache_level = "cache_everything",
    edge_cache_ttl = "240"
  }
}

resource "cloudflare_page_rule" "domain-page-rule8" {
  zone = "${var.domain}"
  target = "${var.domain}/*"
  priority = 8

  actions = {
    cache_level = "bypass"
  }
}

resource "cloudflare_page_rule" "domain-page-rule9" {
  zone = "${var.domain}"
  target = "${var.domain}"
  priority = 9

  actions = {
    browser_check = "off",
    ssl = "full",
    browser_cache_ttl = "240",
    always_online = "off",
    security_level = "low",
    cache_level = "bypass",
    disable_performance = false,
  }
}

resource "cloudflare_page_rule" "domain-page-rule10" {
  zone = "${var.domain}"
  target = "${var.domain}"
  priority = 10

  actions = {
    browser_cache_ttl = "30",
    cache_level = "cache_everything",
    edge_cache_ttl = "240"
  }
}


### Modify target to reflect your own subdomains and paths
