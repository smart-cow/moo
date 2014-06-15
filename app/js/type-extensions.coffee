String::rightOf = (char) ->
    @substr(@lastIndexOf(char) + 1)

String::leftOf = (char) ->
    @substr(0, @indexOf(char))