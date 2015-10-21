module = angular.module('impac.components.widgets-common.data-not-found',[])

module.directive('commonDataNotFound', ($templateCache, $log, $http, ImpacAssets, ImpacTheming) ->
  return {
    restrict: 'A',
    scope: {
    	widgetEngine: '='
    },
    controller: ($scope) ->
      $scope.bgImage = ''
      $scope.content = ImpacTheming.get().dataNotFoundConfig
      baseDir = ImpacAssets.get('dataNotFound')
      if $scope.widgetEngine and baseDir.length > 0
        # checks for trailing slash and corrects.
        dir = baseDir.split('')
        dir = if dir[dir.length - 1] != '/'
        then dir.concat('/').join('')
        else dir.join('')

        assetPath = dir + $scope.widgetEngine + '.png'
        $http.get(assetPath).then(
          (success) ->
            $scope.bgImage = assetPath
          (error) ->
            $log.warn("Missing data-not-found image for #{$scope.widgetEngine}")
        )

    template: $templateCache.get('widgets-common/data-not-found.tmpl.html'),
  }
)
