## All defined type extension methods are prefixed with m$

String::m$rightOf = (char) ->
    @substr(@lastIndexOf(char) + 1)

String::m$leftOf = (char) ->
    @substr(0, @indexOf(char))

Array::m$first = (predicate, includeIndex = false) ->
    for element, index in @ when predicate(element)
        if includeIndex
            return [element, index]
        else
            return element
    return if includeIndex then [null, null] else null

Array::m$remove = (predicate) ->
    while true
        [element, index] = @.m$first(predicate, true)
        return unless element?
        @splice(index, 1)

