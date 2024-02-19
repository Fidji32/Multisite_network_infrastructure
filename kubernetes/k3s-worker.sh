# Warn if first parameters are not set
if [ -z "$1" ]; then
  echo "You should provide the control node’s IP as first parameter"
  exit 1
fi

if [ -z "$2" ]; then
  echo "You should provide the token as second parameter"
  exit 1
fi

IP="$1"
TOKEN="$2"

echo "Executing the install script with two environment variables"
echo "K3S_URL=https://$IP:6443"
echo "K3S_TOKEN=$TOKEN"

K3S_URL="https://$IP:6443" K3S_TOKEN="$TOKEN" ./k3s-master.sh
