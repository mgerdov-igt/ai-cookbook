$script:WorkItems = @(
    [pscustomobject]@{ Id = 101; Title = 'Review sign-in errors'; Status = 'Open'; Owner = 'Ava' }
    [pscustomobject]@{ Id = 102; Title = 'Update deployment guide'; Status = 'In Progress'; Owner = 'Ben' }
    [pscustomobject]@{ Id = 103; Title = 'Check backup alert'; Status = 'Open'; Owner = 'Ben' }
    [pscustomobject]@{ Id = 104; Title = 'Close old access request'; Status = 'Done'; Owner = 'Ava' }
)

function Get-WorkItems {
    [CmdletBinding()]
    param()

    $script:WorkItems
}
