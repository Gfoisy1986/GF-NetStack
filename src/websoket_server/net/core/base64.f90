module base64_module
    implicit none

    character(len=*), parameter :: b64chars = &
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

contains

    function base64_encode(bin) result(out)
        character(len=*), intent(in) :: bin
        character(len=:), allocatable :: out
        integer :: i, pad, n
        integer :: b1, b2, b3
        character(len:), allocatable :: tmp

        n = len(bin)
        pad = mod(3 - mod(n, 3), 3)

        allocate(character(len=((n+pad)/3)*4) :: tmp)

        i = 1
        do while (i <= n)
            b1 = iachar(bin(i:i))
            b2 = merge(iachar(bin(i+1:i+1)), 0, i+1 <= n)
            b3 = merge(iachar(bin(i+2:i+2)), 0, i+2 <= n)

            tmp((i-1)/3*4+1:(i-1)/3*4+4) = &
                b64chars(ishft(b1, -2)+1:ishft(b1, -2)+1) // &
                b64chars(ior(ishft(iand(b1,3),4), ishft(b2,-4))+1:ior(ishft(iand(b1,3),4), ishft(b2,-4))+1) // &
                b64chars(ior(ishft(iand(b2,15),2), ishft(b3,-6))+1:ior(ishft(iand(b2,15),2), ishft(b3,-6))+1) // &
                b64chars(iand(b3,63)+1:iand(b3,63)+1)

            i = i + 3
        end do

        ! Ajouter '=' si nécessaire
        if (pad > 0) then
            tmp(len(tmp)-pad+1:len(tmp)) = repeat("=", pad)
        end if

        out = tmp
    end function base64_encode

end module base64_module
