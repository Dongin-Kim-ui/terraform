# "neo", "trinity", "morhpeus"

variable "names" {
  type        = list(string)
  default     = ["neo", "trinity", "morhpeus"]
  description = "List test"
}

output "names" {
  value       = var.names
}

# # "NEO" , "TRINITY" , "MORHPEUS"
output upper_names {
  value       = [for name in var.names : upper(name)]
  description = "Upper names"
}

output "short_upper_names" {
  value       = [for name in var.names : upper(name) if length(name) < 5]
  description = "Short upper names"
}


#####################################################
#
# map type variable
# {"neo":, "hero" "trinity":, "love interest", "morpheus": "mentor"}
#####################################################

variable "hero_thousand_faces" {
  default = {
    neo      = "hero"
    trinity  = "love interest"
    morpheus = "mentor"
  }
  type        = map(string)
  description = "Map test"
}

output "name_role" {
  value = var.hero_thousand_faces
}

output "bios" {
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
}

# ["NEO is the HERO", "TRINITY is the love INTERREST", "MORPHEUS is the MENTOR"] 

output "bios_upper" {
  value = [for name, role in var.hero_thousand_faces : "${upper(name)} is the ${upper(role)}"]
}

# {"NEO" : "HERO", "TRINITY": "LOVE INTEREST", "MORPHEUS": "MENTOR"}
output "bios_upper_map" {
  value = {for name, role in var.hero_thousand_faces : upper(name) => upper(role)}
}

