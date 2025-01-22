module "my_vpc" {
  source = "../modules/vpc"

}

module "my_ec2" {
  source = "../modules/ec2"
  subnet_id = module.my_vpc.subnet_id
  sg_ids = [module.my_vpc.sg_id]
  keypair = "mykeypair"
}




