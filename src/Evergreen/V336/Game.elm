module Evergreen.V336.Game exposing (..)

import Array
import Evergreen.V336.Go
import Evergreen.V336.Id
import Evergreen.V336.Message
import Evergreen.V336.SecretId
import Evergreen.V336.UserSession
import Evergreen.V336.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V336.Go.GameMsg
    | GoSetupMsg Evergreen.V336.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V336.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V336.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V336.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V336.Go.ValidatedSetup (Array.Array Evergreen.V336.Go.ActionWithTime) Evergreen.V336.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V336.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V336.WordSpellingGame.ActionWithTime) Evergreen.V336.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Evergreen.V336.UserSession.ToBeFilledInByBackend (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Evergreen.V336.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V336.Go.GameModel
    | WordSpellingGame_Game Evergreen.V336.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V336.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V336.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V336.Go.ValidatedSetup (Array.Array Evergreen.V336.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V336.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V336.WordSpellingGame.ActionWithTime) Evergreen.V336.WordSpellingGame.Shared
