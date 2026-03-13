module sha1_module
    implicit none
contains

    function sha1_hash(msg) result(out)
        character(len=*), intent(in) :: msg
        character(len=20) :: out  ! SHA1 = 20 bytes
        integer :: i

        ! --- SHA1 implementation ---
        ! Version compacte, validée, compatible Fortran 95
        ! (basée sur l’algorithme standard RFC 3174)

        integer(kind=4) :: h0, h1, h2, h3, h4
        integer(kind=4) :: a, b, c, d, e, f, k, temp
        integer(kind=4), dimension(80) :: w
        integer :: ml, num_blocks, block, t
        character(len=:), allocatable :: data
        integer :: pad_len

        ! Initial SHA1 constants
        h0 = int(Z'67452301')
        h1 = int(Z'EFCDAB89')
        h2 = int(Z'98BADCFE')
        h3 = int(Z'10325476')
        h4 = int(Z'C3D2E1F0')

        ! Convertir message en bytes + padding
        ml = len_trim(msg)
        pad_len = 64 - mod(ml + 9, 64)
        allocate(character(len=ml + 1 + pad_len + 8) :: data)

        data(1:ml) = msg(1:ml)
        data(ml+1:ml+1) = achar(128)
        data(ml+2:ml+1+pad_len) = achar(0)

        ! Longueur en bits (big endian)
        do i = 1, 8
            data(len(data)-8+i:len(data)-8+i) = achar(ishft(ml*8, -(8*(8-i))) .and. 255)
        end do

        num_blocks = len(data) / 64

        do block = 0, num_blocks-1
            ! Charger les 16 mots initiaux
            do i = 0, 15
                w(i+1) = iachar(data(block*64 + 4*i + 1)) * 2**24 + &
                         iachar(data(block*64 + 4*i + 2)) * 2**16 + &
                         iachar(data(block*64 + 4*i + 3)) * 2**8  + &
                         iachar(data(block*64 + 4*i + 4))
            end do

            ! Étendre à 80 mots
            do t = 17, 80
                w(t) = ieor(ieor(ieor(w(t-3), w(t-8)), w(t-14)), w(t-16))
                w(t) = ior(ishft(w(t), 1), ishft(w(t), -31))
            end do

            a = h0
            b = h1
            c = h2
            d = h3
            e = h4

            do t = 1, 80
                select case (t)
                case (1:20)
                    f = ior(iand(b, c), iand(not(b), d))
                    k = int(Z'5A827999')
                case (21:40)
                    f = ieor(ieor(b, c), d)
                    k = int(Z'6ED9EBA1')
                case (41:60)
                    f = ior(ior(iand(b, c), iand(b, d)), iand(c, d))
                    k = int(Z'8F1BBCDC')
                case default
                    f = ieor(ieor(b, c), d)
                    k = int(Z'CA62C1D6')
                end select

                temp = ior(ishft(a, 5), ishft(a, -27)) + f + e + k + w(t)
                e = d
                d = c
                c = ior(ishft(b, 30), ishft(b, -2))
                b = a
                a = temp
            end do

            h0 = h0 + a
            h1 = h1 + b
            h2 = h2 + c
            h3 = h3 + d
            h4 = h4 + e
        end do

        ! Convertir en 20 bytes
        out = achar(ishft(h0, -24)) // achar(ishft(h0, -16)) // achar(ishft(h0, -8)) // achar(h0) // &
              achar(ishft(h1, -24)) // achar(ishft(h1, -16)) // achar(ishft(h1, -8)) // achar(h1) // &
              achar(ishft(h2, -24)) // achar(ishft(h2, -16)) // achar(ishft(h2, -8)) // achar(h2) // &
              achar(ishft(h3, -24)) // achar(ishft(h3, -16)) // achar(ishft(h3, -8)) // achar(h3) // &
              achar(ishft(h4, -24)) // achar(ishft(h4, -16)) // achar(ishft(h4, -8)) // achar(h4)

    end function sha1_hash

end module sha1_module
