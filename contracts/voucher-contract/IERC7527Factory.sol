// SPDX-License-Identifier: MIT
import {Asset} from "./IERC7527Agency.sol";

interface IERC7527Factory{
    /**
     * @dev Deploys a new agency and app clone and initializes both.
        * @param agencyImplementation The address of the agency implementation.
        * @param asset The parameter of asset of the agency.
        * @param immutableAgencyData The immutable data are stored in the code region of the created proxy contract of agencyImplementation.
        * @param agencyInitData If init data is not empty, calls proxy contract of agencyImplementation with this data.
        * @param appImplementation The address of the app implementation.
        * @param immutableAppData The immutable data are stored in the code region of the created proxy contract of appImplementation.
        * @param appInitData If init data is not empty, calls proxy contract of appImplementation with this data.
        * @return agencyInstance The address of the created proxy contract of agencyImplementation.
     */
    function createWrap(
        address payable agencyImplementation,
        Asset calldata asset,
        bytes calldata immutableAgencyData,
        bytes calldata agencyInitData,
        address appImplementation,
        bytes calldata immutableAppData,
        bytes calldata appInitData
    ) external returns(address);
}
