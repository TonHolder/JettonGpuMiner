#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# install dependencies
apt update
apt install git openssl -y
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || echo "Can't install libssl1.1"
rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb
wget http://mirrors.kernel.org/ubuntu/pool/main/n/nano/nano_4.8-1ubuntu1_amd64.deb
dpkg -i nano_4.8-1ubuntu1_amd64.deb || echo "Can't install nano"
rm nano_4.8-1ubuntu1_amd64.deb


# Check if miner is installed
if [ ! -d "$HOME/miner" ]; then
    echo "Miner not installed. Installing."

    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs

    cd "$HOME" || exit
    git clone https://github.com/TonHolder/JettonGpuMiner.git miner

    cd miner || exit
    echo "Installing miner..."
else
    cd "$HOME/miner" || exit
    echo "Miner installed. Updating."
    git pull
    echo "Updating miner..."
fi


# Create test file
cat > test.sh << EOL
#!/bin/bash

"$HOME"/miner/pow-miner-cuda -g 0 -F 128 -t 5 kQBWkNKqzCAwA9vjMwRmg7aY75Rf8lByPA9zKXoqGkHi8SM7 229760179690128740373110445116482216837 53919893334301279589334030174039261347274288845081144962207220498400000000000 10000000000 kQBWkNKqzCAwA9vjMwRmg7aY75Rf8lByPA9zKXoqGkHi8SM7 mined.boc
EOL

# Create start file
cat > mine.sh << EOL
#!/bin/bash

GIVERS=1000
TIMEOUT=4
API="tonapi"

GPU_COUNT=\$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l) > /dev/null 2>&1

if [ "\$GPU_COUNT" = "0" ] || [ "\$GPU_COUNT" = "" ]; then
    echo "Cant get GPU count. Aborting."
    exit 1
fi

echo "Detected \${GPU_COUNT} GPUs"

if [ "\$1" = "gram" ]; then
    echo "Starting GRAM miner"
    if [ "\$GPU_COUNT" = "1" ]; then
        CMD="node send_universal.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --timeout \${TIMEOUT}"
    else
        CMD="node send_multigpu.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --gpu-count \${GPU_COUNT} --timeout \${TIMEOUT}"
    fi
elif [ "\$1" = "mrdn" ]; then
    echo "Starting Meridian miner"
    if [ "\$GPU_COUNT" = "1" ]; then
        CMD="node send_meridian.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --timeout \${TIMEOUT}"
    else
        CMD="node send_multigpu_meridian.js --api \${API} --bin ./pow-miner-cuda --givers \${GIVERS} --gpu-count \${GPU_COUNT} --timeout \${TIMEOUT}"
    fi
else
    echo -e "Invalid argument. Use \${GREEN}./mine.sh mrdn\${NC} or \${GREEN}./mine.sh gram\${NC} to start miner."
    exit 1
fi


npm install

while true; do
    \$CMD
done;
EOL

chmod +x test.sh
chmod +x mine.sh

if [ ! -f config.txt ]; then
    cat > config.txt << EOL
SEED=
TONAPI_TOKEN=
TARGET_ADDRESS=
EOL
fi

echo ""
echo    "+------------------------------------------------------------------------+"
echo -e "|                         ${GREEN}Installation complete!${NC}                         |"
echo -e "|                                                                        |"
echo -e "| Start mining with ${GREEN}./mine.sh mrdn${NC} or ${GREEN}./mine.sh gram${NC}                     |"
echo -e "| ${RED}DONT FORGET TO CREATE config.txt WITH ${GREEN}nano config.txt${NC} ${RED}BEFORE START!!!${NC}  |"
echo -e "| ${YELLOW}Donations are welcome: kurimuzonakuma.ton${NC}                              |"
echo    "+------------------------------------------------------------------------+"
