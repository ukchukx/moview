defmodule Moview.Movies.Cinema do
  @moduledoc """
  All cinema functions return {:ok, result} when successful else {:error, reason/changeset}
  """

  require Logger

  alias Moview.Movies.Cinema.Impl

  def clear_state, do: Impl.clear_state()

  def seed_from_db, do: Impl.seed_from_db()

  def create_cinema(%{name: _, address: _, city: _} = params) do
    Impl.create_cinema(params)
  end

  def update_cinema(id, %{} = params) do
    Impl.update_cinema(id, params)
  end

  def delete_cinema(cinema) do
    Impl.delete_cinema(cinema)
  end

  def get_cinema(id) do
    Impl.get_cinema(id)
  end

  def get_cinemas_by_name(name) do
    Impl.get_cinemas_by_name(name)
  end

  def get_cinemas do
    Impl.get_cinemas()
  end

  def cinema_name(%{data: %{name: name, branch_title: branch, city: city}}) do
    case branch do
      "" -> "#{name}, #{city}"
      _ -> "#{name} (#{branch}), #{city}"
    end
  end
  def cinema_name(_), do: ""


  def seed do
    Logger.info("Seeding cinemas")
    results =
    [
      %{
        id: 288621440596258850,
        name: "Genesis Cinemas",
        address: "The Palms Shopping Mall, Lekki",
        city: "Lagos",
        branch_title: "The Palms Mall",
        url: "https://www.genesiscinemas.com/locations/palms-mall-lekki-lagos/"
      },
      %{
        id: 288621440596278685,
        name: "Genesis Cinemas",
        address: "Ceddi Plaza, 264 Tafawa Balewa Way",
        city: "Abuja",
        branch_title: "Ceddi Plaza",
        url: "https://www.genesiscinemas.com/ceddi-plaza-abuja/"
      },
      %{
        id: 288626352374578286,
        name: "Genesis Cinemas",
        address: "Gateway Mall, Airport road, Lugbe",
        city: "Abuja",
        branch_title: "Gateway Mall",
        url: "https://www.genesiscinemas.com/locations/gateway-mall-abuja/"
      },
      %{
        id: 288621440596279336,
        name: "Genesis Cinemas",
        address: "Delta Mall, Effurun",
        city: "Effurun",
        branch_title: "Delta Mall",
        url: "https://www.genesiscinemas.com/warri-delta-mall-effurun/"
      },
      %{
        id: 288626352374584160,
        name: "Genesis Cinemas",
        address: "Asaba Mall, Asaba",
        city: "Asaba",
        branch_title: "Delta Mall",
        url: "https://www.genesiscinemas.com/asaba-mall-delta-state/"
      },
      %{
        id: 288621440596279966,
        name: "Genesis Cinemas",
        address: "Maryland Mall, Ikorodu Road",
        city: "Lagos",
        branch_title: "Maryland Mall",
        url: "https://www.genesiscinemas.com/maryland-mall-lagos/"
      },
      %{
        id: 288621440596280370,
        name: "Genesis Cinemas",
        address: "Genesis Center, 39 Tombia Street, GRA Phase 2",
        city: "Port Harcourt",
        branch_title: "Genesis Center",
        url: "https://www.genesiscinemas.com/genesis-center-port-harcourt/"
      },
      %{
        id: 288621440596281142,
        name: "Genesis Cinemas",
        address: "3 Egbu Road",
        city: "Owerri",
        branch_title: "Owerri Mall",
        url: "https://www.genesiscinemas.com/owerri-mall-owerri/"
      },
      %{
        id: 288621440596282038,
        name: "Genesis Cinemas",
        address: "Novare Mall, Sangotedo, Ajah",
        city: "Lagos",
        branch_title: "Novare Mall",
        url: "https://www.genesiscinemas.com/novare-lekki-mall-sangotedo-lagos"
      },
      %{
        id: 288621440596283352,
        name: "Silverbird Cinemas",
        address: "Ibom Tropicana Entertainment Centre",
        city: "Uyo",
        branch_title: "Ibom Tropicana Entertainment Centre",
        url: "https://silverbirdcinemas.com/cinema/uyo/"
      },
      %{
        id: 288621440596284027,
        name: "Silverbird Cinemas",
        address: "Jabi Lake Mall",
        city: "Abuja",
        branch_title: "Jabi Lake Mall",
        url: "https://silverbirdcinemas.com/cinema/jabi/"
      },
      %{
        id: 288621440596285007,
        name: "Silverbird Cinemas",
        address: "Plot 1161, Memorial Drive, By Musa Yar'adua Center, Central Business District",
        city: "Abuja",
        branch_title: "Silverbird Entertainment Center",
        url: "https://silverbirdcinemas.com/cinema/sec-abuja/"
      },
      %{
        id: 288621440596287158,
        name: "Silverbird Cinemas",
        address: "Festival Mall (Golden Tulip Hotel Compound), Amuwo Odofin",
        city: "Lagos",
        branch_title: "Festac",
        url: "https://silverbirdcinemas.com/cinema/festac/"
      },
      %{
        id: 288621440596287682,
        name: "Silverbird Cinemas",
        address: "Ikeja City Mall, 174 / 194, Obafemi Awolowo way, Alausa, Ikeja",
        city: "Lagos",
        branch_title: "Ikeja",
        url: "https://silverbirdcinemas.com/cinema/ikeja/"
      },
      %{
        id: 288621440596288432,
        name: "Silverbird Cinemas",
        address: "133, Ahmadu Bello Way, Victoria Island",
        city: "Lagos",
        branch_title: "Galleria - V.I",
        url: "https://silverbirdcinemas.com/cinema/galleria/"
      },
      %{
        id: 288621440596289698,
        name: "Filmhouse Cinemas",
        address: "Ade Bayero Mall, Zoo road",
        city: "Kano",
        branch_title: "Ado Bayero Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-kano"
      },
      %{
        id: 288621440596290133,
        name: "Filmhouse Cinemas",
        address: "Leisure Mall, Adeniran Ogunsanya road, Surulere",
        city: "Lagos",
        branch_title: "Leisure Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-surulere"
      },
      %{
        id: 288621440596290721,
        name: "Filmhouse Cinemas",
        address: "Heritage Mall, Cocoa road, Dugbe",
        city: "Ibadan",
        branch_title: "Heritage Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-dugbe"
      },
      %{
        id: 288621440596291170,
        name: "Filmhouse Cinemas",
        address: "Venture Mall, Samonda",
        city: "Ibadan",
        branch_title: "Venture Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-samonda"
      },
      %{
        id: 288621440596291829,
        name: "Filmhouse Cinemas",
        address: "Port Harcourt Mall, 1 Azikiwe Road",
        city: "Port Harcourt",
        branch_title: "Port Harcourt Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-port-harcourt"
      },
      %{
        id: 288621440596292707,
        name: "Filmhouse Cinemas",
        address: "Igbatoro road",
        city: "Akure",
        branch_title: "",
        url: "https://filmhouseng.com/cinema/filmhouse-akure"
      },
      %{
        id: 288621440596292717,
        name: "Filmhouse Cinemas",
        address: "Lagos/Benin Expressway, Opposite University of Benin",
        city: "Benin",
        branch_title: "Voen Shopping Mall",
        url: "https://filmhouseng.com/cinema/filmhouse-benin"
      },
      %{
        id: 288621440596292727,
        name: "Filmhouse Cinemas",
        address: "Okunde Bluewater Zone, Off Remi Olowude Road, Water Corporation Road",
        city: "Lagos",
        branch_title: "Twin Waters Entertainment Center",
        url: "https://filmhouseng.com/cinema/filmhouse-oniru"
      },
      %{
        id: 288621440596294087,
        name: "Ozone Cinemas",
        address: "E-Centre 1-11 Commercial avenue, Yaba",
        city: "Lagos",
        branch_title: "",
        url: "https://www.ozonecinemas.com/now_showing.php"
      }
    ]
    |> Enum.map(&create_cinema/1)

    Logger.info("Done seeding cinemas: #{inspect Enum.count(results)} results returned")
  end

end

