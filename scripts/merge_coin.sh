source ./scripts/config.sh

sui client switch --address $admin

primary_coin=0x9e7dae4d80f3c10737c73db4ed30735bee1d849122eda8d54cdd367444f4bf00

coin_to_merges=(
    "0x0c74d33c4c55e258dbe476450f801122267fbab81ac5e5b4d44a809c4b0c08cb"
    "0xf0d5d0fdae3a35654bbc1ddd25757ad656076e34ab75ac70ba6671036d583e52"
    "0xd261f7face437da242694f6a39dab4f9de8f4a974a6f220e1d3177bdb714ed45"
    "0x5aab88e2891201699f59f98811cc163b3475ee1a1215f9b79d2d0d84e553367d"
    "0xd47ade2d227df9713bda8027a7b223bf4b3dcce9b664dbb9dc7dd9a701a6c14b"
    "0x30a46da41754aedddd593f57fef1c6d5cf7e2206b7ba6b5bb8028d7a366a7357"
)

for coin_to_merge in "${coin_to_merges[@]}"; do
    echo "Merging coin $coin_to_merge into primary coin $primary_coin"
    sui client merge-coin --primary-coin $primary_coin --coin-to-merge $coin_to_merge
done

sui client switch --address $admin
