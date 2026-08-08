module Evergreen.V348.Game exposing (..)

import Array
import Evergreen.V348.Go
import Evergreen.V348.Id
import Evergreen.V348.Message
import Evergreen.V348.SecretId
import Evergreen.V348.UserSession
import Evergreen.V348.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V348.Go.GameMsg
    | GoSetupMsg Evergreen.V348.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V348.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V348.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V348.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V348.Go.ValidatedSetup (Array.Array Evergreen.V348.Go.ActionWithTime) Evergreen.V348.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V348.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V348.WordSpellingGame.ActionWithTime) Evergreen.V348.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Evergreen.V348.UserSession.ToBeFilledInByBackend (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Evergreen.V348.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V348.Go.GameModel
    | WordSpellingGame_Game Evergreen.V348.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V348.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V348.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V348.Go.ValidatedSetup (Array.Array Evergreen.V348.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V348.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V348.WordSpellingGame.ActionWithTime) Evergreen.V348.WordSpellingGame.Shared
