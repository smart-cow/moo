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
    modified = false
    while @.m$removeFirst(predicate)
        modified = true
    return modified


Array::m$removeFirst = (predicate) ->
    [element, index] = @.m$first(predicate, true)
    return false unless element?
    @splice(index, 1)
    return true


Array::m$clear = ->
    @splice(0, @length)
    return @



Array::m$unique = ->
    map = { }
    for e in @
        map[e] = typeof(e) == typeof(0)
    ret = [ ]
    for own key, isNum of map
        if isNum
            ret.push(+key)
        else
            ret.push(key)
    return ret

Array::m$sortBy = (key) ->
    @sort (a, b) ->
        aVal = a[key]
        bVal = b[key]
        if aVal < bVal
            return -1
        if aVal > bVal
            return 1
        return 0


window.m$log = (str, obj) -> console.log("#{str}: %o", obj)


class Set
    constructor: (initialData = []) ->
        @map = { }
        @insertArray(initialData)

    insert: (e) =>
        if @map[e]?
            return false
        @map[e] = typeof(e) == typeof(0)
        return true

    insertArray: (array) =>
        (@insert(e) for e in array)

    toArray: =>
        (@convertType(e) for own e of @map)

    iter: =>
        @toArray()

    convertType: (e) =>
        if @map[e] then +e else e

window.Set = Set