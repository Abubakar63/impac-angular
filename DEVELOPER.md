# Impac! Angular Frontend Library
---
### Installation

Make sure you have nodejs installed, and then:

```
  npm install
```

Install package via bower.

```
  bower install --save impac-angular=git@github.com:maestrano/impac-angular.git#develop
```

Add `'maestrano.impac'` module as dependancy of your angular application.

```
  angular.module('yourApp', ['maestrano.impac'])
```

Embed angular-impac's wrapper directive `'impacDashboard'`. You can use either Element or Attribute binding

```
  <impac-dashboard></impac-dashboard>
             <!-- or -->
  <div impac-dashboard></div>
```

### Configuration

impac-angular requires that you configure it's **ImpacLinkingProvider service** with some core data.

#### API

##### linkData(options)
_type_: Object<br>
_usage_: Linking core User data into impac-angular to meet the requirements of the library, and keeping concerns seperate.

**user**<br>
_type_: Function<br>
_return_: Promise -> {sso_session: ssoSession, ... }<br>
_usage_: Retrieving user details & sso_session key for authenticating querys to Impac! API, and displaying user data e.g name.

**organizations**<br>
_type_: Function<br>
_return_: Promise -> {organizations: [ userOrgs, ... ], currentOrgId: currentOrgId}<br>
_usage_: Retrieving organizations and current organization id.

#### Example

```
  angular
    .module('yourApp', [])
    .run( (ImpacLinkingProvider, ImpacConfigProvider) ->
    
      data = 
          user: ImpacConfig.getUserData
          organizations: ImpacConfig.getOrganizations
            
      ImpacLinkingProvider.linkData(data)

    )
  )
  
```
### Optional Configurations
[TODO: Expand on this section]<br>

There are other provider services for dynamically configuring impac-angular on an app by app basis. For example, there is a routes provider for configuring api end-points and such. There is a theming provider for configuring chart colour themes and soon more. There is an assets provider for configuring static assets.


<!--  # notes as reminder of optional config instructions to document.
    - custom dhb selector templates
      - valid url = 'app/views/foobar.html
-->

### Developement

Easiest way to develop for impac-angular is by creating a **[bower link](http://bower.io/docs/api/#link)**. (Essentially a sym-link, so will sync with any changes).

Steps are:

```
  // Pointing bower to your local version of impac-angular
   
  cd impac-angular/ 
  bower link  
  cd your-project/
  bower link impac-angular
  
  // Uninstalling bower link, and pointing bower to original github path.
  
  cd impac-angular/
  bower uninstall impac-angular
  bower update
```

#### How-to: Create a widget

1. Define the widget's template. The base widgets templates list is retrieved from the MNOE API, within each dashboard object. Each widget template will have a structure similar to the following:

  ```JSON
  {
    // engine called in Impac! API
    // -----
    path: 'accounts/balance',
    
    // optional - name of the template to use for your widget. In this case, 'accounts-balance.tmpl.html' will be used. If no metadata['template'] is defined, the path is used to determine the template name
    // -----
    metadata: {
      template: 'accounts/balance'
    },
    
    // name to be displayed in the widgets selector
    // -----
    name: 'Account balance', 
    
    // description tooltip to be displayed in the widgets selector
    // -----
    desc: "Display the current value of a given account",
    
    // font awesome icon to be displayed in the widgets selector
    // -----
    icon: "university",
    
    // number of bootstrap columns of the widget (value can be 3 or 6)
    // -----
    width: 3
  }
  ```
  
2. Create the widget's files:
  - in /src/components/widgets/, add a folder 'category-widget-name' (e.g: accounts-my-new-widget).
  - in this new folder, add three files:
    - 'accounts-my-new-widget.directive.js.coffee' containing the angular directive and controller defining your widget's behaviour.
    - 'accounts-my-new-widget.tmpl.html' containing the template of your widget.
    - 'accounts-my-new-widget.less' containing the stylesheet of your widget.

3. Define the widget's directive. According to widget.directive.js.coffee, it will define at least these parameters:
  - **$scope.parentDashboard**, which is the dashboard object that contains the widget object in its *widgets* list.
  - **$scope.widget**, which is the widget object.

4. Start implementing the widget's controller. It must contain at least the following elements:
  - **settingsPromises**, which is an array of promises, contains a promise for each custom sub-directive that you add to your widget (e.g: a setting, a chart...).
  *It is essential that you pass a deferred object (initialized by $q.defer()) to each setting or chart that you want to add to your widget: it will be used to make sure the setting is properly initialized before the widget can call its functions.*
  - **$scope.widget.initContext()** is the function that will be called just after the widget has retrieved its content from the API. It should be implemented, and used to determine if the widget can be displayed properly, and to initialize potential specific variables.
  - **$scope.widget.format()** is the function that will be called when the widget is ready to draw its chart. It should use the ChartFormatterSvc functions to format the data properly. Once the chart data is ready, it can be passed to the chart directive through a notify() called on its deferred object. E.g:
  ```coffeescript
  $scope.drawTrigger = $q.defer()
  w.format = ->
    [...]
    # formats the widget content in data that will be readable by Chartjs
    chartData = ChartFormatterSvc.lineChart([inputData],options)
    # passes chartData to the chart directive, and calls chart.draw()
    $scope.drawTrigger.notify(chartData)
  ```

5. Notify the widget's main directive that the widget's specific context has been loaded and is ready. To do that, we use a deferred object that is initialized in the main directive (widget.directive.js.coffee), and resolved at the end of the specific directive (accounts-my-new-widget.directive.js.coffee):
  ```coffeescript
  $scope.widgetDeferred.resolve(settingsPromises)
  ```
  **IMPORTANT**: The settingsPromises array defined in 1/ has to be passed back to the main directive to make sure it will wait for all the settings to be initialized before calling the widget's #show function.

#### How-to: Create a setting

1. Create the setting's files:
  - in /src/components/widgets-settings/, add a folder 'setting-name' (e.g: my-new-setting).
  - in this new folder, add three files:
    - 'my-new-setting.directive.js.coffee' containing the angular directive and controller defining your setting behaviour.
    - 'my-new-setting.tmpl.html' containing the template of your setting.
    - 'my-new-setting.less' containing the stylesheet of your setting.

2. Define your setting's directive. It requires at least the following attributes:
  ```coffeescript
    scope: {
      parentWidget: '=' // widget object containing the setting object 
      deferred: '=' // deferred object that will be resolved once the setting context is loaded
    },
  ``` 

3. Start implementing your setting's controller:
  - create a **setting** object with a unique identifier:
  ```coffeescript
    setting = {}
    setting.key = "my-new-setting"
    ```
    - implement the **setting.initialize()** function, which must be used to set the setting's default parameters
    - implement the **setting.toMetadata()** function, which will be called when the setting content has to be stored in the Maestrano config. It must return a javascript hash that will be directly stored into widget.metadata. For instance, if setting.toMetadata() returns `{ my_new_setting: true }`, once the widget is updated, it will contain: `widget.metadata.my_new_setting = true`

4. Push the setting in the parent widget settings list: `$scope.widget.settings.push(setting)`

5. Notify the parent widget that the setting's context has been loaded and is ready: `$scope.deferred.resolve(setting)`.
**IMPORTANT**: The parent widget's #show method (= call to the Impac! API to retrieve the widget's content) will be called only once all the settings are loaded (= once they have resolved their `$scope.deferred` object). 

##### Conventions specific to settings development

- **Avoid** using the `$scope.parentWidget` inside of the setting's controller: when you have to call a method belonging to the widget object, pass a callback to the directive as an argument. When you need to access some data contained into `$scope.parentWidget.content`, try passing an object to the directive as well. Eg:
```coffeescript
scope: {
  parentWidget: '='
  deferred: '='
  callBackToWidget: '=onActivate'
  widgetContentData: '=data'
}
```

### Conventions within impac-angular

#### General
- HTML Templates **must not use double-quotes for strings** (I'm looking at you, Ruby devs). Only html attribute values may be wrapped in double qoutes. 
  - **REASON**: when gulp-angular-templatecache module works its build magic, having double quotes within double quotes breaks the escaping.
 
- We have found [this angular style guide](https://github.com/johnpapa/angular-styleguide) to be an excellent reference which outlines good ways to write angular. I try to write CoffeeScript so it compiles in line with this style guide.

#### File Naming

- Slug style file naming, e.g `this-is-slug-style`.
- Prefix file basename rather than adding to filename. e.g `some-file.svc.coffee` instead of `some-file-svc.coffee`, or `some-file.modal.html` instead of `some-file-modal.html`.

<br>
**IMPORTANT:**
Widget folder and file names must be the same as the widget's category that is stored in the back-end, for example:

```
  # widget data returned from maestrano database
  widget: {
    category: "invoices/aged_payables_receivables",
    ...
  }
```
**Component folder & file name should be:** `invoices-aged-payables-receivables`


#### Stylesheets

The goal is to be able to work on a specific component / piece of functionality and be able to quickly isolate the javascript and css without having to dig through a 1000 line + css / js file, and also preventing styles from bleeding.

Stylesheets should be kept within the components file structure, with styles concerning that component.

Only main stylesheets should be kept in the stylesheets folder, like `variables.less`, `global.less`, and `mixins.less`, etc.

Component specific styles should be wrapped in a containing ID to prevent bleeding. 

```
  #module__component-name {
    /* styles that wont bleed and are easily identifiable as only within this component */
    ul {}
  }
```
Template to match above:

``` 
  <!-- components/component-name/component-name.tmpl.html -->
  <div id="module__component-name">
    <!-- html template for component -->
  </div>
```

Running `gulp less:inject` will inject `@import` declarations from `.less` files in `components/` into `impac-angular.less`.

Running `gulp less:concat` will then concatinate all less files into a one.

Running `gulp less:compile` will compile the dist less file into a dist css and min.css file. Note, you will need to uncomment an `@import` of `bower_components/bootstrap` in the `impac-angular.less`.
  
### Tests

Test should be created within service or component folders. Just be sure to mark them with a .spec extension.

Example: 

```
  components/
    some-component/
      some-component.directive.coffee
      some-component.directive.spec.js
  services/
    some-service/
      some-service.service.coffee
      some-service.service.spec.js
```

To run tests, first build impac-angular with `gulp build`. Then run `gulp test`.

To run tests for production on the minified version, first build with `gulp build:dist`. Then run `gulp test:dist`.

**NOTE:** with `gulp build:dist` you will need to uncomment the bower_components bootstrap `@import` in the `impac-angular.less` file.

### Bugs, Refactor and Improvements


### Roadmap


### Licence 
Copyright 2015 Maestrano Pty Ltd

