class jsonform.FieldCollection

  constructor: (config) ->
    @config = config
    @tmpl = JST["fields/fieldcollection"]
    @jel = $("<div></div>")
    @el = @jel[0]

    # Array that itself holds an array of fields. This makes
    # the field collection work for a single field or a set of fields.
    @items = []

  render: ->

    @jel.html(@tmpl(@config))

    @jel.find(".jfAdd").click( (e) =>
      return if $(this).is("[disabled]")
      e.preventDefault()
      @addItem()
    )

    if $().sortable
      @jel.find(".jfCollection").sortable(
        placeholder: '<span class="placeholder">&nbsp;</span>'
        itemSelector: '.jfCollectionItem'
        handle: 'i.jfSort'
        onDrop: (item, container, _super) =>
          _super(item, container)

          # FIELD COLLECTION ITEM HERE.
          # sort by what number of child the el is
          @items = _.sortBy(@items, (field) ->
            field.jel.index()
          )

          jsonform.helpers.changed()
      )

  getValues: ->
    results = _.map(@items, (item) -> item.getValue())
    _.without(results, "", undefined, null)

  addItem: (defaultValue) ->

    # remove some values that are meant for the
    # collection.
    fieldConfig = _.extend({}, @config)
    delete fieldConfig.jfTitle
    delete fieldConfig.jfHelper
    field = jsonform.helpers.newField(fieldConfig)
    # field

    item = new jsonform.FieldCollectionItem(@config, defaultValue)
    @jel.find(".jfCollection").append(item.el)
    item.render()
    @items.push(item)

    # listen for click on del
    item.jel.on("delete_clicked", (e, item) =>
      item.jel.remove()
      @items = _.without(@items, item)
      @checkAddState()
      jsonform.helpers.changed()
    )

    # check if we hide or show the add button
    @checkAddState()

    # update sortable
    if $().sortable
      @jel.find(".jfCollection").sortable("refresh")

    # call changed to update json
    jsonform.helpers.changed()

  fieldsFromValues: (vals) ->

    # if the config has a jfType in the root object, it means
    # that each array item is a single value.
    if @config.jfType

      # if this field needs extra values for setvalue,
      # call the function. This is mostly for select boxes
      # where we also need the label besides the value
      if jsonform[@config.jfType].findExtraValues
        jsonform[@config.jfType].findExtraValues(@config, vals, (vals) =>
          _.each(vals, (val) => @addItem(val))
        )
      else
        _.each(vals, (val) => @addItem(val))

    # if it doesn't have a jfType, each array item will have multiple
    # values.
    else
      console.log vals

  checkAddState: ->
    if @config.jfMax
      if @items.length >= @config.jfMax
        @jel.find(".jfAdd").attr("disabled", "disabled")
      else
        @jel.find(".jfAdd").removeAttr("disabled")
