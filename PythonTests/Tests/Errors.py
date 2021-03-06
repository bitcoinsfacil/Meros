#Exception is used when the Python code fails.

#EmptyError Exception. Used when a test is empty.
class EmptyError(
    Exception
):
    pass

#NodeError Exception. Used when the node fails.
class NodeError(
    Exception
):
    pass

#SuccessError Exception. Used when a test succeeds yet needs to cut execution short.
class SuccessError(
    Exception
):
    pass

#TestError Exception. Used when a test fails.
class TestError(
    Exception
):
    pass
