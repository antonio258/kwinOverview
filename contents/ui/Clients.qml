import QtQuick 2.2
import org.kde.kwin 2.0 as KWinLib
//import org.kde.kwin 2.0;
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as Plasma

// Trying to get the image provider to work.
import org.kde.activities.settings 0.1
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddonsComponents

import org.kde.plasma.activityswitcher 1.0 as ActivitySwitcher

import org.kde.activities 0.1 as Activities

Item {
  id: kwinDesktopThumbnailContainer
  property int desktop: 0
  property bool isMain: false
  property bool isLarge: false
  x: 0
  y: 0
  scale: 1

  Grid {
    id: clientGridLayout
    visible: true
    //x: 0
    //y: 0
    property int numberOfChildren: 0
    scale: 1

    anchors.verticalCenter: parent.verticalCenter
    rows: { return _returnMatrixSize() }
    // No order guaranteed, here.
    columns: { return _returnMatrixSize() }

    add: Transition {
      NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutBounce }
    }

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutBounce }
    }

    onRowsChanged: {
      testRows.start();
    }
    NumberAnimation { id: testRows; property: "y"; duration: 400; easing.type: Easing.OutBounce }
    NumberAnimation on columns { property: "x"; duration: 400; easing.type: Easing.OutBounce }

    function _overlapsDesktop(x, y) {
      // Here, we're going to determine if we're in a new desktop.
      //console.log(workspace.currentDesktop);
      //console.log(x, y);
      // If we drag it out of the bar, send it to the current desktop.
      if (y > dash.height) {
        return workspace.currentDesktop;
      }
      for (var d = 1; d <= workspace.desktops; d++) {
        // We need to check if we're within the new bounds.  That's height and width!
        // or just width, actually.
        // x and y are now global coordinates.
        // We have workspace.desktops, and our screen width is activeScreen.width
        //console.log(x, (d)*kwinDesktopThumbnailContainer.width + desktopThumbnailGridBackgrounds.width/(workspace.desktops) + dash.height*main.screenRatio, d);
        if (x < (d)*kwinDesktopThumbnailContainer.width + desktopThumbnailGridBackgrounds.width/(workspace.desktops) + dash.height*dashboard.screenRatio) {
          return d-1
        }
        //if (x > (d-1*width)+activeScreen.width/(2*workspace.desktops)) {
        //  return d;
        //}
      }
      return 0;

    }

    function _onDesktop() {
      var c;
      var oD = 0;
      for (c = 0; c < workspace.clientList().length; c++) {
        if (workspace.clientList()[c].desktop-1 == desktop) {
          oD++;
        }
      }
      if (clientGridLayout.onDesktop == 0) {
        oD = 1;
      }
      return oD;
    }

    function _returnMatrixSize() {
      // Figure out how many we have on the desktop, then calculate an
      // an appropriate row x column size.
      var oD = _onDesktop();
      // Just do it manually for the moment; not elegant, but effective.
      // Not sure what math library I'd need and I'm feeling lazy.
      if (oD <= 1)
        return 1
      if (oD <= 4)
        return 2
      if (oD <= 9)
        return 3
      if (oD <= 16)
        return 4
      if (oD < 25)
        return 5
      return 36
    }

    Component.onCompleted: {
      //updateClients();
      kwinDesktopThumbnailContainer.updateGrid();
      // We do want to change when a client changes desktops, but.
      //workspace.clientList()[clientId].desktopChanged.connect(updateGrid);
      //mainBackground.stateChanged.connect(runAnimations);
      if (workspace.currentDesktop-1 == kwinDesktopThumbnailContainer.desktop) {
        kwinDesktopThumbnailContainer.isMain = true;
        kwinDesktopThumbnailContainer.visible = true;
      }
      if (!kwinDesktopThumbnailContainer.isLarge) {
        workspace.currentDesktopChanged.connect(kwinDesktopThumbnailContainer.updateGrid);
      } else {
        // If we're the main one, we actually just want to go invisible and let the other one in.
        workspace.currentDesktopChanged.connect(kwinDesktopThumbnailContainer.swapGrids);
      }
      //workspace.currentDesktopChanged.connect(updateGrid);
      //workspace.numberDesktopsChanged
      workspace.clientAdded.connect(kwinDesktopThumbnailContainer.updateGrid);
      workspace.clientRemoved.connect(kwinDesktopThumbnailContainer.updateGrid);
      workspace.currentActivityChanged.connect(kwinDesktopThumbnailContainer.updateGrid);
      workspace.currentActivityChanged.connect(kwinDesktopThumbnailContainer.updateGrid);
    }
  }

  PropertyAnimation {
    id: moveMainToLeft
    target: kwinDesktopThumbnailContainer
    duration: 1000
    running: false
    property: 'x'
    to: -dashboard.screenWidth
    from: 0
    easing.amplitude: 2
    easing.type: Easing.InOutQuad
    onStopped: {
      kwinDesktopThumbnailContainer.visible = false;
    }
  }
  PropertyAnimation {
    id: moveMainToRight
    target: kwinDesktopThumbnailContainer
    duration: 1000
    running: false
    property: 'x'
    to: dashboard.screenWidth
    from: 0
    easing.amplitude: 2
    easing.type: Easing.InOutQuad
    onStopped: {
      kwinDesktopThumbnailContainer.visible = false;
    }
  }
  PropertyAnimation {
    id: moveNewToLeft
    target: kwinDesktopThumbnailContainer
    duration: 1000
    property: 'x'
    running: false
    from: dashboard.screenWidth
    to: 0
    easing.amplitude: 2
    easing.type: Easing.InOutQuad
  }
  PropertyAnimation {
    id: moveNewToRight
    target: kwinDesktopThumbnailContainer
    duration: 1000
    property: 'x'
    running: false
    from: -dashboard.screenWidth
    to: 0
    easing.amplitude: 2
    easing.type: Easing.InOutQuad
  }

  function swapGrids(oldDesktop, newDesktop) {
    console.log('WHICH ONE IS WHICH!?');
    console.log(oldDesktop, newDesktop);
    // If we're not the 'main', but we ARE current, we want to become visible and change our
    // x position (to the right or left, don't care right now), then animate a change to 0, 0.
    if (workspace.currentDesktop-1 == kwinDesktopThumbnailContainer.desktop) {
      if (!kwinDesktopThumbnailContainer.isMain) {
        // We need to know which way we're moving.  But, ah, hmmm.
        // Which one is the old one?
        if (oldDesktop-1 < kwinDesktopThumbnailContainer.desktop) {
          moveNewToLeft.restart();
        } else {
          moveNewToRight.restart();
        }
        kwinDesktopThumbnailContainer.isMain = true;
        kwinDesktopThumbnailContainer.visible = true;
        //kwinDesktopThumbnailContainer.x = -dashboard.screenWidth;
      }
    }
    if (isMain && workspace.currentDesktop-1 != kwinDesktopThumbnailContainer.desktop) {
        // Now, handle moving the OTHER one.
        if (workspace.currentDesktop-1 > kwinDesktopThumbnailContainer.desktop) {
          moveMainToLeft.restart();
        } else {
          moveMainToRight.restart();
        }
        kwinDesktopThumbnailContainer.isMain = false;
        //kwinDesktopThumbnailContainer.x = dashboard.screenWidth;
    }
  }


  function updateGridOnDesktopChange() {
    // Probably won't work.
    var c; // client
    var nClients = clientGridLayout.children.length;
    if (kwinDesktopThumbnailContainer.isMain) {
      kwinDesktopThumbnailContainer.desktop = workspace.currentDesktop-1;
    }
    for (c = 0; c < nClients; c++) {
      // Kill all the children.
        clientGridLayout.children[c].destroy();
      }
    clientGridLayout.numberOfChildren = 0;
    // But we actually need to rebuild the whole grid.  Huh!
    clientGridLayout.rows = clientGridLayout._returnMatrixSize();
    clientGridLayout.columns = clientGridLayout._returnMatrixSize();
    updateClients();
}

  function updateGrid() {
    // Probably won't work.
    //if (kwinDesktopThumbnailContainer.isMain) {
    //  kwinDesktopThumbnailContainer.desktop = workspace.currentDesktop-1;
    //}
    // But we actually need to rebuild the whole grid.  Huh!
    var c; // client
    var nClients = clientGridLayout.children.length;
    //for (c = 0; c < clientGridLayout.numberOfChildren; c++) {
    for (c = 0; c < nClients; c++) {
      // Kill all the children.
      // Ah, I see this fails out sometimes.
      if (clientGridLayout.children[c].clientObject) {
        if (clientGridLayout.children[c].clientObject.desktop-1 != kwinDesktopThumbnailContainer.desktop) {
        //if (clientGridLayout.children[c].currentDesktop-1 != kwinDesktopThumbnailContainer.desktop) {
          // Destroy anything NOT on the desktop.
          clientGridLayout.children[c].destroy();
        }
      }
    }
    clientGridLayout.rows = clientGridLayout._returnMatrixSize();
    clientGridLayout.columns = clientGridLayout._returnMatrixSize();
    updateClients();
}
    // Now, we build up our windows.
    //model: workspace.clientList().length

  function updateClients() {
    var c; // client
    //var d; // Desktop
    //var onDesktop = 0;
    //array var alreadyExists = [];
    clientGridLayout.numberOfChildren = 0;
    for (c = 0; c < workspace.clientList().length; c++) {
      // check if the client is on our desktop.
      console.log('TESTING ACTIVITIES');
      console.log(workspace.clientList()[c].activities);
      console.log(allActivities.id);
      if (workspace.clientList()[c].desktop-1 == desktop && (workspace.clientList()[c].activities == '' || workspace.clientList()[c].activities == workspace.currentActivity )) {
        // Do we already exist?
        var e;
        var alreadyExists = false;
        for (e = 0; e < clientGridLayout.children.length; e++) {
          //console.log(clientGridLayout.children[e].clientObject == workspace.clientList()[c]);
          //if (clientGridLayout.children[e].clientObject.windowId == workspace.clientList()[c].windowId) {
          if (clientGridLayout.children[e].clientObject == workspace.clientList()[c]) {
            // Basically, did we destroy it from this list?
            alreadyExists = true;
            //break;
            //alreadyExists = false;
            // So scale it!
            clientGridLayout.children[e].width = kwinDesktopThumbnailContainer.width / clientGridLayout.columns;
            clientGridLayout.children[e].height = kwinDesktopThumbnailContainer.height / clientGridLayout.columns;
          }
        }
        // If it doesn't already exist, create it!
        // What we PROBABLY need is the stacking order.
        // It seems to draw in reverse list order.  So the 'last' item added to the list
        // is the first thing we draw in KWin.
        if (!alreadyExists) {
          clientGridLayout.numberOfChildren++;
          var clientThumbnail = Qt.createComponent('ClientThumbnail.qml')
          //console.log(Object.getOwnPropertyNames(workspace.clientList()[c]));
          if( clientThumbnail.status == Component.Error )
              console.debug("Error:"+ clientThumbnail.errorString() );
          // Why are we doing this here?  We're ditching the repeater,
          // as we want to dynamically create things.
          // This means destruction and creation when we add new clients.
          // In addition, we only create objects when we need them.
          clientThumbnail.createObject(clientGridLayout,
                                      // Custom ID for destruction later.
                                      {id: 'desktopId' + desktop + 'clientId' + c,
                                      //'background': model.get(0).background,
                                      'clientObject': workspace.clientList()[c],
                                      'originalWidth': kwinDesktopThumbnailContainer.width / clientGridLayout.columns,
                                      'originalHeight': kwinDesktopThumbnailContainer.height / clientGridLayout.columns,
                                      'scale': (kwinDesktopThumbnailContainer.height / kwinDesktopThumbnailContainer.width) / (dashboard.screenHeight/dashboard.screenWidth),
                                      'clientId': c,
                                      'currentDesktop': workspace.clientList()[c].desktop,
                                      'visible': true,
                                      'x': 0, 'y': 0,
                                      //'x': clientGridLayout.mapFromGlobal(workspace.clientList()[c].x).x,
                                      //'y': clientGridLayout.mapFromGlobal(workspace.clientList()[c].y).y,
                                      'clientRealX': workspace.clientList()[c].x,
                                      // Account for the fucking dock, if any.
                                      'clientRealY': workspace.clientList()[c].y,
                                      'clientRealWidth': workspace.clientList()[c].width,
                                      'clientRealHeight': workspace.clientList()[c].height,
                                      'height': kwinDesktopThumbnailContainer.height / clientGridLayout.columns,
                                      'width': kwinDesktopThumbnailContainer.width / clientGridLayout.columns});
        }
      }
    }
  }
}
