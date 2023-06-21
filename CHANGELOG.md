## [1.2.3] - 21/06/23
* Not attempt to refresh if AuthHttpClientKeys.noAuthenticateOverride passed

## [1.2.2] - 18/06/23
* Allow async code logic on mappers and parsers
  
## [1.2.0] - 14/04/23
* Allow async code logic on mappers and parsers

## [1.1.6] - 29/12/22
* Small change on refresh token logic

## [1.1.5] - 8/08/22
* Improve refresh token logic 

## [1.1.4] - 8/08/22
* Improve error log in [HttpAuthClient]

## [1.1.3] - 2/07/22
* Fix crash on .send method
  When trying to access `request.bodyFields`

## [1.1.1] - 2/06/22
* Small  fix in refresh logic 

## [1.1.0] - 11/05/22
* Reworked Refresh Token Logic
* Deprecated properties:
  * `refreshTokenDebounceTime`
  *  Rename `onParseRefreshTokenResponse` -> `refreshTokenResponseParser`
  *  Added `onRefreshTokenFailure`, `refreshTokenRequestBodyMapper`


## [1.0.4] - 15/10/21
* Define default in different way

## [1.0.3] - 11/08/21
* Some null check changes
## [1.0.2] - 06/08/21
* Make refresh token fields not mandatory

## [1.0.0] - 06/08/21

* Make Null-Safety

## [0.0.4] - 24/11/20

* Added `onRefreshToken` callback

## [0.0.3] - 15/09/20

* Added `refreshToken` capability

## [0.0.2] - 30/07/20

* Added "Authorization" header to `send` http method when request of type Multipart

## [0.0.1] - TODO: Add release date.

* TODO: Describe initial release.
