# Assumes that at-chat and the runtime repo are in the same parent directory
cd ../runtime/nixos
nix flake lock --update-input at-chat
cd ../scripts
DEBUG=1 ./lxelm.sh updateServerEnterprise martin-s
