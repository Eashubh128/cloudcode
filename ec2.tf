provider  "aws" {
  region     = "ap-south-1"
  access_key  ="AKIAYTDD2J7LD2YPWQKJ"
  secret_key = "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" 
} 

resource "aws_instance" "testinc" {
  ami             = "ami-0447a12f28fddb066"
  instance_type   = "t2.micro"
  key_name        = "awskey2"
  security_groups = ["launch-wizard-3"]


  
  tags = {
    Name = "server"
   
  }

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key   =   file("C:/users/sk/Downloads/awskey2.pem")
    host     = aws_instance.testinc.public_ip

     
  }


provisioner "remote-exec" {
    inline = [
       "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
     
    ]
  }
}


resource "aws_ebs_volume" "testvol" {
  availability_zone = aws_instance.testinc.availability_zone
  size              = 10
  
  tags = {
    Name = "ebs-vol"
  }
}





resource "aws_volume_attachment" "ebsattach" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.testvol.id
  instance_id  = aws_instance.testinc.id
  force_detach = true


  provisioner "remote-exec" {
    connection {
      agent       = "false"
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/sk/Downloads/awskey2.pem")
      host        = aws_instance.testinc.public_ip
    }
    
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html/",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Eashubh128/cloudauto.git /var/www/html/"
    ]
  }
depends_on = [
    aws_ebs_volume.testvol
  ]
}
  




resource "aws_s3_bucket" "testbucket" {
  bucket = "git-code-for-terra"
  acl    = "public-read"

	 provisioner "local-exec" {
		command  =  "git clone https://github.com/Eashubh128/cloudauto.git  terraform"
	}
	
	tags =  {
		Name = "terras3"
		Environment  =  "Production"
	}
versioning {
    enabled  =   true
}


}



resource "aws_s3_bucket_object" "bucket-push" {
  bucket = aws_s3_bucket.testbucket.bucket
  key   =   "facebook.jpg"
  source = "C:/users/sk/Desktop/test/tf/terraform/facebook.jpg"
  acl    = "public-read"
}


resource "aws_cloudfront_distribution" "s3-web-distribution" {
  origin {
    domain_name = "${aws_s3_bucket.testbucket.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.testbucket.id}"

	custom_origin_config {
		http_port  =  80
		https_port  =  80
		origin_protocol_policy  = "match-viewer"
		origin_ssl_protocols  =  [ "TLSv1", "TLSv1.1", "TLSv1.2" ]
	}
 
  }


  enabled             = true
  is_ipv6_enabled     = true


	


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.testbucket.id}"


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
     
    }
  }


  tags = {
    Name        = "TerraformDistribution"
    Environment = "Production"
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }


  depends_on = [
    aws_s3_bucket.testbucket
  ]

 

}

resource"null_resource""nullenvvar"{
provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'echo export url=${aws_s3_bucket.testbucket.bucket_domain_name} >> /etc/apache2/envvars' ",
      "sudo sysytemctl restart apache2"
    ]
  }
}



resource "null_resource"  "nullcall" {
	provisioner "local-exec" {
		command = "start chrome  ${aws_instance.testinc.public_ip}/facebook.jpg"
                                         
		}
	}


  
