module = angular.module('impac.components.widgets-settings.accounts-list', [])

# There is no template associated to this setting, and though it won't appear in the 'settings' panel
# However, as its metadata has to be initialized from, and saved to Impac!, we build ListAccounts as a setting
module.controller('SettingAccountsListCtrl', ($scope, ImpacWidgetsSvc) ->

  # ---------------------------------------------------------
  # ### Populate the widget
  # ---------------------------------------------------------

  w = $scope.parentWidget

  # Used by the 'delete' button in the accounts list and by the comboBox
  w.moveAccountToAnotherList = (account, src, dst, triggerUpdate=true) ->
    return if _.isEmpty(src) || _.isEmpty(account)
    dst ||= []
    _.remove src, (acc) -> account.uid == acc.uid
    dst.push(account)
    ImpacWidgetsSvc.updateWidgetSettings(w, w.metadata) if triggerUpdate
    return null

  w.resetAccounts = (src, dst, triggerUpdate=false) ->
    srcCopy = angular.copy(src)
    _.forEach(srcCopy, (account) -> w.moveAccountToAnotherList(account, src, dst, triggerUpdate))
    return null



  # ---------------------------------------------------------
  # ### Setting definition
  # ---------------------------------------------------------

  setting = {}
  setting.key = "accounts-list"

  setting.initialize = ->
    setting.isInitialized = false
    w.remainingAccounts = []
    w.selectedAccounts = []

    if w.content? && !_.isEmpty(w.content.complete_list)
      w.remainingAccounts = angular.copy(w.content.complete_list)

      # Impac! returns the list of all the accounts, and we want that:
      # completeList + savedList = list of all accounts
      if !_.isEmpty(w.metadata.accounts_list)
        angular.forEach(w.metadata.accounts_list, (accUid) ->
          acc = _.find(w.content.complete_list, (acc) ->
            acc.uid == accUid
          )
          w.moveAccountToAnotherList(acc,w.remainingAccounts,w.selectedAccounts,false)
        )

      setting.isInitialized = true

  setting.toMetadata = ->
    return { accounts_list: _.map(w.selectedAccounts, ((acc) -> acc.uid)) } if setting.isInitialized

  w.settings.push(setting)

  # Setting is ready: trigger load content
  # ------------------------------------
  $scope.deferred.resolve($scope.parentWidget)
)

module.directive('settingAccountsList', () ->
  return {
    restrict: 'A',
    scope: {
      parentWidget: '='
      deferred: '='
    },
    controller: 'SettingAccountsListCtrl'
  }
)
