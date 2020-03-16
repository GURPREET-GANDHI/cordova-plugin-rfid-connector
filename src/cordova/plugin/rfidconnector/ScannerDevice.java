package cordova.plugin.rfidconnector;

import org.apache.cordova.CallbackContext;


public interface ScannerDevice {

    /**
     * @param deviceAddress
     * @param callbackContext
     * @return
     */
    void connect(final String deviceAddress, final CallbackContext callbackContext);

    /**
     * @param callbackContext
     * @return
     */
    void isConnected(final CallbackContext callbackContext);

    /**
     * @param callbackContext
     * @return
     */
    void disconnect(final CallbackContext callbackContext);

    /**
     * @param callbackContext
     * @return
     */
    void getDeviceInfo(final CallbackContext callbackContext);

    /**
     * @param useASCII
     * @param callbackContext
     * @return
     */
    void scanRFIDs(final boolean useASCII, final CallbackContext callbackContext);
    //
    // /**
    // * @param useASCII
    // * @param callbackContext
    // * @return
    // */
    // void startScan(final String useASCII, final CallbackContext callbackContext);

    /**
     * @param tagID
     * @param useAscii
     * @param callbackContext
     * @return
     */
    void search(final String tagID, final boolean useAscii, final CallbackContext callbackContext);

    /**
     * @param power
     * @param callbackContext
     * @return
     */
    void setOutputPower(final int power, final CallbackContext callbackContext);

    /**
     * @param useASCII
     * @param callbackContext
     */
    void subscribeScanner(final boolean useASCII, final CallbackContext callbackContext);

    /**
     * @param callbackContext
     */
    void unsubscribeScanner(final CallbackContext callbackContext);

    /**
     * @param useASCII
     * @param callbackContext
     */
    void startSearch(String tagID, boolean useAscii, CallbackContext callbackContext);

    /**
     * @param callbackContext
     */
    void stopSearch(CallbackContext callbackContext);
}
