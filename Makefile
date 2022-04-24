all:

test:
	./testthat tests

clean:
	$(RM) -r tests/output
