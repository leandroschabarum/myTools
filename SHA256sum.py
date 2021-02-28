import hashlib, sys

file_path = input("[ inform file path ] />_ ")
SHA256hash = hashlib.sha256()

with open(file_path, 'rb') as file:

	for block in iter(lambda: file.read(4096), bytes()):
		SHA256hash.update(block)

	print("\n{}\t{}".format(SHA256hash.hexdigest(), file_path))

sys.exit(0)
