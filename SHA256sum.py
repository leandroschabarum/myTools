import hashlib

filename = input("[ inform file path ] />_ ")
sha256_hash = hashlib.sha256()

with open(filename, 'rb') as file:

	for byte_block in iter(lambda: file.read(4096), b''):
		sha256_hash.update(byte_block)

	print("\n{}\t{}".format(sha256_hash.hexdigest(), filename))
