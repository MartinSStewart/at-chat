module Evergreen.V316.Game exposing (..)

import Array
import Evergreen.V316.Go
import Evergreen.V316.Id
import Evergreen.V316.Message
import Evergreen.V316.SecretId
import Evergreen.V316.UserSession
import Evergreen.V316.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V316.Go.GameMsg
    | GoSetupMsg Evergreen.V316.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V316.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V316.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V316.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V316.Go.ValidatedSetup (Array.Array Evergreen.V316.Go.ActionWithTime) Evergreen.V316.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V316.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V316.WordSpellingGame.ActionWithTime) Evergreen.V316.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Evergreen.V316.UserSession.ToBeFilledInByBackend (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Evergreen.V316.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V316.Go.GameModel
    | WordSpellingGame_Game Evergreen.V316.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V316.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V316.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V316.Go.ValidatedSetup (Array.Array Evergreen.V316.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V316.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V316.WordSpellingGame.ActionWithTime) Evergreen.V316.WordSpellingGame.Shared
