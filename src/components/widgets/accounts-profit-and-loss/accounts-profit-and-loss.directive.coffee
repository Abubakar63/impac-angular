module = angular.module('impac.components.widgets.accounts-profit-and-loss',[])

module.controller('WidgetAccountsProfitAndLossCtrl', ($scope, $q, ChartFormatterSvc, $filter, ImpacWidgetsSvc) ->

  w = $scope.widget

  # Define settings
  # --------------------------------------
  $scope.orgDeferred = $q.defer()
  $scope.timeRangeDeferred = $q.defer()
  $scope.widthDeferred = $q.defer()
  $scope.chartDeferred = $q.defer()

  settingsPromises = [
    $scope.orgDeferred.promise
    $scope.timeRangeDeferred.promise
    $scope.widthDeferred.promise
    $scope.chartDeferred.promise
  ]


  # Widget specific methods
  # --------------------------------------
  w.initContext = ->
    if $scope.isDataFound = angular.isDefined(w.content) && !_.isEmpty(w.content.summary) && !_.isEmpty(w.content.dates)

      $scope.dates = w.content.dates
      $scope.unCollapsed = w.metadata.unCollapsed || []

      if w.metadata.selectedElements
        $scope.selectedElements = []
        angular.forEach(w.metadata.selectedElements, (sElem) ->
          foundElem = _.find(w.content.summary, (statement)->
            statement.name == sElem.name
          )

          if !foundElem
            angular.forEach(w.content.summary, (statement) ->
              foundElem ||= _.find(statement.accounts, (account)->
                sElem.id == account.id
              ) if statement.accounts?
            )

          $scope.selectedElements.push(foundElem) if foundElem
        )

      w.width = 6 unless $scope.selectedElements? && $scope.selectedElements.length > 0

  $scope.getElementChartColor = (index) ->
    ChartFormatterSvc.getColor(index)

  $scope.getLastDate = ->
    _.last($scope.dates) if $scope.dates?

  $scope.getLastValue = (element) ->
    _.last(element.totals) if element.totals?

  $scope.getClassColor = (aTotal) ->
    if parseInt(aTotal) > 0
      return 'positive'
    else if parseInt(aTotal) < 0
      return 'negative'
    else
      return null

  $scope.getName = (element) ->
    element.name.replace(/_/g, " ") if element? && element.name?

  # --->
  # TODO selectedElement and collapsed should be factorized as settings or 'commons'
  $scope.toggleSelectedElement = (element) ->
    if $scope.isSelected(element)
      $scope.selectedElements = _.reject($scope.selectedElements, (sElem) ->
        if element.id
          sElem.id == element.id
        else
          sElem.name == element.name
      )
      w.format()
      if w.isExpanded() && $scope.selectedElements.length == 0
        w.toggleExpanded()
      else
        ImpacWidgetsSvc.updateWidgetSettings(w,false)
    else
      $scope.selectedElements ||= []
      $scope.selectedElements.push(element)
      w.format()
      if !w.isExpanded()
        w.toggleExpanded()
      else
        ImpacWidgetsSvc.updateWidgetSettings(w,false)

  $scope.isSelected = (element) ->
    if element? && $scope.selectedElements?
      if _.find($scope.selectedElements, (sElem) ->
        if element.id
          sElem.id == element.id
        else
          sElem.name == element.name
      )
        return true
      else
        return false
    else
      return false

  $scope.toggleCollapsed = (element) ->
    if element? && element.name?
      if _.find($scope.unCollapsed, ((name) -> element.name == name))
        $scope.unCollapsed = _.reject($scope.unCollapsed, (name) ->
          name == element.name
        )
      else
        $scope.unCollapsed.push(element.name)
      ImpacWidgetsSvc.updateWidgetSettings(w,false)

  $scope.isCollapsed = (element) ->
    if element? && element.name?
      if _.find($scope.unCollapsed, ((name) -> element.name == name))
        return false
      else
        return true

  $scope.hasElements = ->
    $scope.selectedElements? && $scope.selectedElements.length > 0
  # <---


  # Chart formating function
  # --------------------------------------
  $scope.drawTrigger = $q.defer()
  w.format = ->
    if $scope.isDataFound && $scope.selectedElements? && $scope.selectedElements.length > 0
      all_values_are_positive = true

      inputData = []
      angular.forEach($scope.selectedElements, (sElem) ->
        data = angular.copy(sElem)

        labels = _.map w.content.dates, (date) ->
          if w.metadata.hist_parameters && w.metadata.hist_parameters.period == "YEARLY"
            $filter('date')(date, 'yyyy')
          else if w.metadata.hist_parameters && w.metadata.hist_parameters.period == "QUARTERLY"
            $filter('date')(date, 'MMM-yy')
          else if w.metadata.hist_parameters && (w.metadata.hist_parameters.period == "WEEKLY" || w.metadata.hist_parameters.period == "DAILY")
            $filter('date')(date, 'dd-MMM')
          else
            $filter('date')(date, 'MMM')

        inputData.push({title: data.name, labels: labels, values: data.totals})

        angular.forEach(data.totals, (value) ->
          all_values_are_positive &&= value >= 0
        )
      )

      options = {
        scaleBeginAtZero: all_values_are_positive,
        showXLabels: true,
        datasetFill: $scope.selectedElements.length == 1,
        pointDot: $scope.selectedElements.length == 1,
      }

      chartData = ChartFormatterSvc.lineChart(inputData,options)
      
      # calls chart.draw()
      $scope.drawTrigger.notify(chartData)


  # Mini-settings
  # --------------------------------------
  unCollapsedSetting = {}
  unCollapsedSetting.initialized = false

  unCollapsedSetting.initialize = ->
    unCollapsedSetting.initialized = true

  unCollapsedSetting.toMetadata = ->
    {unCollapsed: $scope.unCollapsed}

  w.settings.push(unCollapsedSetting)

  selectedElementsSetting = {}
  selectedElementsSetting.initialized = false

  selectedElementsSetting.initialize = ->
    selectedElementsSetting.initialized = true

  selectedElementsSetting.toMetadata = ->
    {selectedElements: $scope.selectedElements}

  w.settings.push(selectedElementsSetting)


  # Widget is ready: can trigger the "wait for settigns to be ready"
  # --------------------------------------
  $scope.widgetDeferred.resolve(settingsPromises)
)

module.directive('widgetAccountsProfitAndLoss', ->
  return {
    restrict: 'A',
    controller: 'WidgetAccountsProfitAndLossCtrl'
  }
)