module Evergreen.V335.Game exposing (..)

import Array
import Evergreen.V335.Go
import Evergreen.V335.Id
import Evergreen.V335.Message
import Evergreen.V335.SecretId
import Evergreen.V335.UserSession
import Evergreen.V335.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V335.Go.GameMsg
    | GoSetupMsg Evergreen.V335.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V335.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V335.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V335.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V335.Go.ValidatedSetup (Array.Array Evergreen.V335.Go.ActionWithTime) Evergreen.V335.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V335.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V335.WordSpellingGame.ActionWithTime) Evergreen.V335.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V335.Go.GameModel
    | WordSpellingGame_Game Evergreen.V335.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V335.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V335.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V335.Go.ValidatedSetup (Array.Array Evergreen.V335.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V335.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V335.WordSpellingGame.ActionWithTime) Evergreen.V335.WordSpellingGame.Shared
