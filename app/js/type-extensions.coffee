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

Array::m$contains = (searchItem) ->
    return @indexOf(searchItem) > -1


window.m$log = (str, obj) -> console.log("#{str}: %o", obj)






class @BaseCtrl
    @register: (app, name) ->
        name ?= @name || @toString().match(/function\s*(.*?)\(/)?[1]
        app.controller(name, @)

    @inject: (services...) ->
        @$inject = services




