module = angular.module('impac.components.widgets.accounts-comparison',[])

module.controller('WidgetAccountsComparisonCtrl', ($scope, $q, ChartFormatterSvc, $filter) ->

  w = $scope.widget

  # Define settings
  # --------------------------------------
  $scope.orgDeferred = $q.defer()
  $scope.accountsListDeferred = $q.defer()
  $scope.chartDeferred = $q.defer()
  $scope.paramsCheckboxesDeferred = $q.defer()

  settingsPromises = [
    $scope.orgDeferred.promise
    $scope.accountsListDeferred.promise
    $scope.chartDeferred.promise
    $scope.paramsCheckboxesDeferred.promise
  ]

  # Widget specific methods
  # --------------------------------------
  w.initContext = ->
    $scope.movedAccount = {}
    # defines the available options for params-checkboxes.directive
    $scope.comparisonModeOptions = [{
      id: 'compare_accounts',
      label: 'Compare matching accounts across your companies',
      value: false,
      onChangeCallback: $scope.updateSettings
    }]
    # updates model with saved settings
    if angular.isDefined(w.metadata.comparison_mode) && w.metadata.organization_ids? && w.metadata.organization_ids.length > 1
      angular.merge $scope.comparisonModeOptions, w.metadata.comparison_mode

    $scope.savedAccountsList = gatherSavedAccounts()

    $scope.isDataFound = w.content? && !_.isEmpty(w.content.complete_list) || $scope.isComparisonMode()

    $scope.noComparableAccounts = $scope.isComparisonMode() && w.content? && _.isEmpty(w.content.complete_list)

    $scope.canSelectComparisonMode = scanAccountsForMultiOrgData()

  # scans results from api to determine whether there is data for multiple organizations
  scanAccountsForMultiOrgData = ->
    return false unless w.content?
    _.uniq(_.pluck(w.content.complete_list, 'org_name')).length > 1

  $scope.isComparisonMode = ->
    _.result( _.find($scope.comparisonModeOptions, 'id', 'compare_accounts'), 'value') || false

  $scope.hasAccountsSelected = ->
    return w.selectedAccounts && w.selectedAccounts.length > 0

  $scope.getAccountColor = (anAccount) ->
    if $scope.isComparisonMode()
      ChartFormatterSvc.getColor(_.indexOf(w.selectedAccounts[0].accounts, anAccount))
    else
      ChartFormatterSvc.getColor(_.indexOf(w.selectedAccounts, anAccount))

  $scope.addAccount = (anAccount) ->
    w.moveAccountToAnotherList(anAccount, w.remainingAccounts, w.selectedAccounts)
    w.format()

  $scope.removeAccount = (anAccount) ->
    w.moveAccountToAnotherList(anAccount, w.selectedAccounts, w.remainingAccounts)
    w.format()

  $scope.formatAmount = (anAccount) ->
    return $filter('mnoCurrency')(anAccount.current_balance, anAccount.currency)

  # Returns uids of saved accounts or groups, also converting saved groups into
  # accounts or accounts into groups when switching between comparison mode.
  gatherSavedAccounts = () ->
    savedUids = w.metadata.accounts_list
    return [] if _.isEmpty savedUids
    isComparisonMode = $scope.isComparisonMode()
    areGrouped = savedUids[0].indexOf(':') >= 0
    # when group uids have been saved, and comparison mode is switched off
    if !isComparisonMode && areGrouped
      # deconstruct group uids into account uids
      _.flatten _.map(savedUids, (a) -> a.split(':'))
    # when comparison mode is switch on
    else if isComparisonMode
      # when account uids have been saved, find first matching group by account uid
      unless areGrouped
        for uid in savedUids
          group = _.find(w.content.complete_list, (group) -> group.uid.indexOf(uid) >= 0)
          return [group.uid] if group
      # when group uids have been saved, deconstruct group uids into account uids
      else
        savedUids
        # _.flatten _.map(savedUids, (a) -> a.split(':'))
    else
      savedUids


  # Chart formating function
  # --------------------------------------
  $scope.drawTrigger = $q.defer()
  w.format = ->
    inputData = {labels: [], values: []}
    _.forEach w.selectedAccounts, (account) ->
      if $scope.isComparisonMode()
        _.forEach account.accounts, (groupedAccount) ->
          inputData.labels.push groupedAccount.name
          inputData.values.push groupedAccount.current_balance
      else
        inputData.labels.push account.name
        inputData.values.push account.current_balance

    while inputData.values.length < 15
      inputData.labels.push ""
      inputData.values.push null

    options = {
      showTooltips: false,
      showXLabels: false,
      barDatasetSpacing: 9,
    }
    chartData = ChartFormatterSvc.barChart(inputData,options)

    # calls chart.draw()
    $scope.drawTrigger.notify(chartData)

  # Widget is ready: can trigger the "wait for settigns to be ready"
  # --------------------------------------
  $scope.widgetDeferred.resolve(settingsPromises)
)

module.directive('widgetAccountsComparison', ->
  return {
    restrict: 'A',
    controller: 'WidgetAccountsComparisonCtrl'
  }
)
