module Evergreen.V317.Game exposing (..)

import Array
import Evergreen.V317.Go
import Evergreen.V317.Id
import Evergreen.V317.Message
import Evergreen.V317.SecretId
import Evergreen.V317.UserSession
import Evergreen.V317.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V317.Go.GameMsg
    | GoSetupMsg Evergreen.V317.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V317.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V317.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V317.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V317.Go.ValidatedSetup (Array.Array Evergreen.V317.Go.ActionWithTime) Evergreen.V317.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V317.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V317.WordSpellingGame.ActionWithTime) Evergreen.V317.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Evergreen.V317.UserSession.ToBeFilledInByBackend (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Evergreen.V317.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V317.Go.GameModel
    | WordSpellingGame_Game Evergreen.V317.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V317.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V317.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V317.Go.ValidatedSetup (Array.Array Evergreen.V317.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V317.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V317.WordSpellingGame.ActionWithTime) Evergreen.V317.WordSpellingGame.Shared
