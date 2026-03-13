module crypto_wrapper
    use iso_c_binding
    implicit none

    interface
        subroutine sha1_hash_c(input, len, out20) bind(C)
            import :: c_char, c_int
            character(kind=c_char), dimension(*) :: input
            integer(c_int), value :: len
            character(kind=c_char), dimension(*) :: out20
        end subroutine sha1_hash_c

        function base64_encode_c(input, len, out, outlen) bind(C)
            import :: c_char, c_int
            character(kind=c_char), dimension(*) :: input
            integer(c_int), value :: len
            character(kind=c_char), dimension(*) :: out
            integer(c_int), value :: outlen
            integer(c_int) :: base64_encode_c
        end function base64_encode_c
    end interface

contains

    function sha1_hash_f(str) result(out)
        character(len=*), intent(in) :: str
        character(len=20) :: out
        character(kind=c_char), dimension(:), allocatable :: cstr
        character(kind=c_char), dimension(20) :: digest
        integer :: n

        n = len_trim(str)
        allocate(cstr(n))
        cstr = transfer(str(1:n), cstr)

        call sha1_hash_c(cstr, n, digest)
        out = transfer(digest, out)
    end function sha1_hash_f


    function base64_encode_f(bin) result(out)
        character(len=*), intent(in) :: bin
        character(len=:), allocatable :: out
        character(kind=c_char), dimension(:), allocatable :: inbuf
        character(kind=c_char), dimension(:), allocatable :: outbuf
        integer :: n, outlen, written

        n = len(bin)
        allocate(inbuf(n))
        inbuf = transfer(bin, inbuf)

        outlen = ((n + 2) / 3) * 4
        allocate(outbuf(outlen))

        written = base64_encode_c(inbuf, n, outbuf, outlen)

        allocate(character(len=written) :: out)
        out = transfer(outbuf(1:written), out)
    end function base64_encode_f

end module crypto_wrapper
