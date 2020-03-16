/*global cordova, module*/

//var exec = require('cordova/exec');
//
//var PLUGIN_NAME = 'RFIDConnector';
//
//var RFIDConnector = {
//  getDeviceList: function(arg0, successCallback, failureCallback) {
//    exec(successCallback, failureCallback, PLUGIN_NAME, 'getDeviceList', [arg0]);
//  }
//};
//
//module.exports = RFIDConnector;
cordova.define("cordova/plugin/RFIDConnector", function(require, exports,
		module) {
	var exec = require('cordova/exec');

	var RFIDConnector = function() {
	};

	RFIDConnector.prototype.getDeviceList = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector',
				'getDeviceList', []);
	}

	RFIDConnector.prototype.connect = function(deviceType, deviceID,
			successCallback, failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'connect', [
				deviceType, deviceID ]);
		//		Call the execute methord again to connect if device is zebra & platform is iOS
		if (deviceType === 'Zebra' && cordova.platformId === 'ios') {
			exec(successCallback, failureCallback, 'RFIDConnector', 'connect',
					[ deviceType, deviceID ]);
		}
	}

	RFIDConnector.prototype.isConnected = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'isConnected',
				[]);
	}

	RFIDConnector.prototype.disconnect = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'disconnect',
				[]);
	}

	RFIDConnector.prototype.getDeviceInfo = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector',
				'getDeviceInfo', []);
	}

	RFIDConnector.prototype.scanRFIDs = function(useAscii, successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'scanRFIDs',
				[ useAscii ]);
	}

	RFIDConnector.prototype.search = function(tagID, useAscii, successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'search', [
				tagID, useAscii ]);
	}

	RFIDConnector.prototype.setOutputPower = function(power, successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector',
				'setOutputPower', [ power ]);
	}

	RFIDConnector.prototype.subscribeScanner = function(useAscii,
			successCallback, failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector',
				'subscribeScanner', [ useAscii ]);
	}

	RFIDConnector.prototype.unsubscribeScanner = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector',
				'unsubscribeScanner', []);
	}

	RFIDConnector.prototype.startSearch = function(tagID, useAscii,
			successCallback, failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'startSearch',
				[ tagID, useAscii ]);
	}

	RFIDConnector.prototype.stopSearch = function(successCallback,
			failureCallback) {
		exec(successCallback, failureCallback, 'RFIDConnector', 'stopSearch',
				[]);
	}

	var rfidConnectorplugin = new RFIDConnector();
	module.exports = rfidConnectorplugin;
});
