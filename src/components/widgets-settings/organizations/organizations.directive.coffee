module = angular.module('impac.components.widgets-settings.organizations',[])
module.controller('SettingOrganizationsCtrl', ($scope, $log, ImpacDashboardsSvc) ->

  w = $scope.parentWidget
  w.selectedOrganizations = {}

  $scope.isOrganizationSelected = (orgUid) ->
    !!w.selectedOrganizations[orgUid]

  $scope.toggleSelectOrganization = (orgUid) ->
    w.selectedOrganizations[orgUid] = !w.selectedOrganizations[orgUid]
    $scope.onSelect({orgs: w.selectedOrganizations}) if angular.isDefined( $scope.onSelect )

  # What will be passed to parentWidget
  setting = {}
  setting.key = "organizations"
  setting.isInitialized = false

  # initialization of selected organizations
  setting.initialize = ->
    ImpacDashboardsSvc.load().then(
      (config) ->
        $scope.dashboardOrganizations = config.currentDashboard.data_sources
        if w.metadata? && w.metadata.organization_ids?
          for org in $scope.dashboardOrganizations
            w.selectedOrganizations[org.uid] = _.contains(w.metadata.organization_ids, org.uid)
          setting.isInitialized = true
    )

  setting.toMetadata = ->
    newOrganizations = _.compact(_.map(w.selectedOrganizations, (checked,uid) ->
      uid if checked
    ))
    newOrganizations = [_.first($scope.dashboardOrganizations).uid] if _.isEmpty(newOrganizations)
    return { organization_ids: newOrganizations }

  w.settings.push(setting)

  # Setting is ready: trigger load content
  # ------------------------------------
  $scope.deferred.resolve($scope.parentWidget)
)

module.directive('settingOrganizations', ($templateCache) ->
  return {
    restrict: 'A',
    scope: {
      parentWidget: '='
      deferred: '='
      onSelect: '&?'
    },
    template: $templateCache.get('widgets-settings/organizations.tmpl.html'),
    controller: 'SettingOrganizationsCtrl'
  }
)
