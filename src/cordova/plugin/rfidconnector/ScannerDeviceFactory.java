package cordova.plugin.rfidconnector;

import org.apache.cordova.CordovaPlugin;


/**
 * @author ragadi
 *
 */
public class ScannerDeviceFactory {
    /**
     * Gives specified type of scanner object.
     * 
     * @param rfidConnector
     * 
     * @param aDeviceType
     * @param asciiCommander
     * @return
     */
    public static ScannerDevice getInstance(CordovaPlugin rfidConnector, String aDeviceType) {
        if ("TSL".equals(aDeviceType)) {
            return new TSLScannerDevice(rfidConnector);
        } else if ("Zebra".equals(aDeviceType)) {
            return new ZebraScannerDevice(rfidConnector);
        } else {
            return null;
        }
    }
}
