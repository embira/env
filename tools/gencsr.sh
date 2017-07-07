# Description
#
# References:
# * Generate a CSR with OpenSSL - http://www.rackspace.com/knowledge_center/article/generate-a-csr-with-openssl
# * Certificate Installation: Apache & mod_ssl - https://support.comodo.com/index.php?/Default/Knowledgebase/Article/View/637/37/
# * How to make own boundle file from CRT files - https://support.comodo.com/index.php?/Default/Knowledgebase/Article/View/643/17/
#


if [ $# -eq 0 ]; then
    echo 'Please enter host name'
    exit 1
fi

DOMAIN=`echo $1 | sed s/\\\./_/g`
KEY="${DOMAIN}.key"
CSR="${DOMAIN}.csr"

openssl genrsa -out ./$KEY 2048
openssl req -new -sha256 -key ./$KEY -out ./$CSR

# Verify
echo
echo '-----------'
echo 'Verify CSR:'
echo '-----------'
echo
openssl req -noout -text -in ./$CSR
