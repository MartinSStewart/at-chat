module Evergreen.V307.Game exposing (..)

import Array
import Evergreen.V307.Go
import Evergreen.V307.Id
import Evergreen.V307.Message
import Evergreen.V307.SecretId
import Evergreen.V307.UserSession
import Evergreen.V307.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V307.Go.GameMsg
    | GoSetupMsg Evergreen.V307.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V307.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V307.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V307.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V307.Go.ValidatedSetup (Array.Array Evergreen.V307.Go.ActionWithTime) Evergreen.V307.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V307.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V307.WordSpellingGame.ActionWithTime) Evergreen.V307.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Evergreen.V307.UserSession.ToBeFilledInByBackend (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Evergreen.V307.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V307.Go.GameModel
    | WordSpellingGame_Game Evergreen.V307.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V307.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V307.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V307.Go.ValidatedSetup (Array.Array Evergreen.V307.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V307.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V307.WordSpellingGame.ActionWithTime) Evergreen.V307.WordSpellingGame.Shared
